import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @State private var selectedMonth = Date()
    @State private var selectedTab   = 0

    private var monthTxns: [Transaction] {
        let cal = Calendar.current
        return all.filter { cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthPickerView(date: $selectedMonth).padding()

                Picker("", selection: $selectedTab) {
                    Text("Daily").tag(0)
                    Text("Monthly").tag(1)
                    Text("Charts").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                TabView(selection: $selectedTab) {
                    DailyReportView(transactions: monthTxns).tag(0)
                    MonthlyTrendView(allTransactions: all).tag(1)
                    ChartsView(transactions: monthTxns).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Reports")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Daily Report
struct DailyReportView: View {
    let transactions: [Transaction]

    private var grouped: [(Date, [Transaction])] {
        Dictionary(grouping: transactions) {
            Calendar.current.startOfDay(for: $0.date)
        }
        .sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {
                ForEach(grouped, id: \.0) { day, txns in
                    let inc = txns.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
                    let exp = txns.filter {  $0.isExpense }.reduce(0) { $0 + $1.amount }
                    Section {
                        ForEach(txns) { t in TransactionRow(transaction: t) }
                    } header: {
                        HStack {
                            Text(day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                                .font(.caption.bold())
                            Spacer()
                            if inc > 0 { Text("+\(CurrencyFormatter.compact(inc))").font(.caption).foregroundColor(AppTheme.incomeGreen) }
                            if exp > 0 { Text("-\(CurrencyFormatter.compact(exp))").font(.caption).foregroundColor(AppTheme.expenseRed) }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(Color(.systemGroupedBackground))
                    }
                }
                Spacer(minLength: 90)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Monthly Trend
struct MonthlyTrendView: View {
    let allTransactions: [Transaction]

    private struct MonthStat: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expense: Double
    }

    private var stats: [MonthStat] {
        let cal = Calendar.current
        return (0..<6).compactMap { offset -> MonthStat? in
            guard let m = cal.date(byAdding: .month, value: -offset, to: .now) else { return nil }
            let txns = allTransactions.filter { cal.isDate($0.date, equalTo: m, toGranularity: .month) }
            return MonthStat(
                month: m,
                income:  txns.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount },
                expense: txns.filter {  $0.isExpense }.reduce(0) { $0 + $1.amount }
            )
        }.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("6-Month Trend").font(.headline).padding(.horizontal)
                Chart {
                    ForEach(stats) { s in
                        BarMark(x: .value("Month", s.month, unit: .month),
                                y: .value("Income", s.income))
                        .foregroundStyle(AppTheme.incomeGreen.opacity(0.8))
                        BarMark(x: .value("Month", s.month, unit: .month),
                                y: .value("Expense", s.expense))
                        .foregroundStyle(AppTheme.expenseRed.opacity(0.8))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { v in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 220)
                .padding()
                .cardStyle()
                .padding(.horizontal)

                Spacer(minLength: 90)
            }
            .padding(.top)
        }
    }
}

// MARK: - Charts
struct ChartsView: View {
    let transactions: [Transaction]

    private var expenseByCat: [(String, Double)] {
        var map: [String: Double] = [:]
        transactions.filter { $0.isExpense }.forEach { map[$0.category, default: 0] += $0.amount }
        return map.sorted { $0.value > $1.value }
    }

    private var totalExp: Double { expenseByCat.reduce(0) { $0 + $1.1 } }
    private var totalInc: Double { transactions.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Spending donut
                if !expenseByCat.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Spending by Category").font(.headline)
                        Chart(expenseByCat, id: \.0) { cat, amount in
                            SectorMark(
                                angle: .value("Amount", amount),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("Category", cat))
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        // Legend
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(expenseByCat.prefix(5), id: \.0) { cat, amount in
                                HStack {
                                    Text(categoryInfo(for: cat).emoji)
                                    Text(cat).font(.caption)
                                    Spacer()
                                    Text(CurrencyFormatter.format(amount)).font(.caption.bold())
                                    Text(String(format: "%.0f%%", totalExp > 0 ? amount/totalExp*100 : 0))
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)
                }

                // Income vs Expense donut
                VStack(alignment: .leading) {
                    Text("Income vs Expense").font(.headline)
                    Chart {
                        SectorMark(angle: .value("Income", totalInc), innerRadius: .ratio(0.55), angularInset: 2)
                            .foregroundStyle(AppTheme.incomeGreen)
                        SectorMark(angle: .value("Expense", totalExp), innerRadius: .ratio(0.55), angularInset: 2)
                            .foregroundStyle(AppTheme.expenseRed)
                    }
                    .frame(height: 180)
                    HStack(spacing: 20) {
                        legendDot(AppTheme.incomeGreen, "Income", totalInc)
                        legendDot(AppTheme.expenseRed,  "Expense", totalExp)
                    }
                    .padding(.top, 6)
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)

                Spacer(minLength: 90)
            }
            .padding(.top)
        }
    }

    private func legendDot(_ color: Color, _ label: String, _ value: Double) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundColor(.secondary)
                Text(CurrencyFormatter.format(value)).font(.caption.bold())
            }
        }
    }
}
