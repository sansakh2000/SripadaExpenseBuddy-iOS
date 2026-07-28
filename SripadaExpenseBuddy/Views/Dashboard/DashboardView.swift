import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var showAddTransaction: Bool
    @Binding var showPaywall: Bool
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var selectedMonth = Date()

    private var monthTxns: [Transaction] {
        let cal = Calendar.current
        return transactions.filter { cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }
    private var income:  Double { monthTxns.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount } }
    private var expense: Double { monthTxns.filter {  $0.isExpense }.reduce(0) { $0 + $1.amount } }
    private var savings: Double { income - expense }
    private var spentPct: Double { income > 0 ? expense / income : 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Month picker
                    MonthPickerView(date: $selectedMonth)
                        .padding(.horizontal)

                    // Balance card
                    balanceCard
                        .padding(.horizontal)

                    // Quick feature grid
                    featureGrid
                        .padding(.horizontal)

                    // Recent transactions
                    if !monthTxns.isEmpty {
                        recentSection
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 90) // tab bar clearance
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sripada")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showPaywall = true } label: {
                        Label("Go Pro", systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.gold)
                    }
                }
            }
        }
    }

    // MARK: Balance card
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings")
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
                .textCase(.uppercase)
                .tracking(0.8)

            Text(CurrencyFormatter.format(savings))
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.white)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2)).frame(height: 6)
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * min(spentPct, 1), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Label(CurrencyFormatter.compact(income), systemImage: "arrow.down.circle.fill")
                    .foregroundColor(AppTheme.incomeGreen)
                Spacer()
                Label(CurrencyFormatter.compact(expense), systemImage: "arrow.up.circle.fill")
                    .foregroundColor(AppTheme.expenseRed)
            }
            .font(.subheadline.bold())
        }
        .padding(20)
        .background(AppTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppTheme.violet.opacity(0.35), radius: 12, y: 6)
    }

    // MARK: Feature grid
    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavigationLink(destination: MoneyTrackerView()) {
                FeatureCard(emoji: "🤝", title: "Money Tracker", subtitle: "Lend & borrow", color: .indigo)
            }
            NavigationLink(destination: RecurringView()) {
                FeatureCard(emoji: "🔄", title: "Recurring & EMI", subtitle: "Auto payments", color: .pink)
            }
            NavigationLink(destination: ExportView()) {
                FeatureCard(emoji: "📥", title: "Export Records", subtitle: "CSV / PDF", color: .teal)
            }
            Button { showAddTransaction = true } label: {
                FeatureCard(emoji: "🎙️", title: "Voice Entry", subtitle: "Speak your expense", color: .purple)
            }
        }
    }

    // MARK: Recent transactions
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(monthTxns.prefix(5)) { txn in
                TransactionRow(transaction: txn)
            }
        }
    }
}

// MARK: - Supporting views

struct MonthPickerView: View {
    @Binding var date: Date
    private let months: [Date] = {
        (0..<12).compactMap { offset in
            Calendar.current.date(byAdding: .month, value: -offset, to: Date())
        }
    }()

    var body: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(date.formatted(.dateTime.month(.wide).year()))
                .font(.subheadline.bold())
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .disabled(Calendar.current.isDate(date, equalTo: .now, toGranularity: .month))
        }
        .foregroundColor(AppTheme.violet)
    }

    private func shiftMonth(_ delta: Int) {
        date = Calendar.current.date(byAdding: .month, value: delta, to: date) ?? date
    }
}

struct FeatureCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(emoji).font(.title2)
            Text(title).font(.subheadline.bold()).foregroundColor(.white)
            Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    private var info: CategoryInfo { categoryInfo(for: transaction.category) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(info.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Text(info.emoji).font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category).font(.subheadline.bold())
                if !transaction.note.isEmpty {
                    Text(transaction.note).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Text((transaction.isExpense ? "-" : "+") + CurrencyFormatter.format(transaction.amount))
                .font(.subheadline.bold())
                .foregroundColor(transaction.isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen)
        }
        .padding(12)
        .cardStyle()
    }
}
