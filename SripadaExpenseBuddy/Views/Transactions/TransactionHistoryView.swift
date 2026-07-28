import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @State private var filter: FilterType = .all
    @State private var searchText = ""
    @State private var selectedMonth = Date()

    enum FilterType: String, CaseIterable {
        case all = "All"; case expense = "Expenses"; case income = "Income"
    }

    private var monthTxns: [Transaction] {
        let cal = Calendar.current
        return all.filter { cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var filtered: [Transaction] {
        monthTxns
            .filter { filter == .all || (filter == .expense) == $0.isExpense }
            .filter { searchText.isEmpty || $0.category.localizedCaseInsensitiveContains(searchText)
                                         || $0.note.localizedCaseInsensitiveContains(searchText) }
    }

    private var grouped: [(String, [Transaction])] {
        Dictionary(grouping: filtered) { txn in
            txn.date.formatted(.dateTime.day().month(.wide).year())
        }
        .sorted { $0.key > $1.key }
    }

    private var totalIncome:  Double { monthTxns.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount } }
    private var totalExpense: Double { monthTxns.filter {  $0.isExpense }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthPickerView(date: $selectedMonth)
                    .padding()

                // Totals strip
                HStack {
                    statChip("Income",  CurrencyFormatter.compact(totalIncome),  AppTheme.incomeGreen)
                    statChip("Expense", CurrencyFormatter.compact(totalExpense), AppTheme.expenseRed)
                    statChip("Saved",   CurrencyFormatter.compact(totalIncome - totalExpense), AppTheme.violet)
                }
                .padding(.horizontal)

                // Filter picker
                Picker("Filter", selection: $filter) {
                    ForEach(FilterType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No transactions",
                        systemImage: "tray",
                        description: Text("Add your first transaction with the + button.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(grouped, id: \.0) { dateStr, txns in
                            Section(header: Text(dateStr).font(.caption).textCase(.none)) {
                                ForEach(txns) { txn in
                                    TransactionRow(transaction: txn)
                                        .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                                        .listRowBackground(Color.clear)
                                }
                                .onDelete { idxSet in deleteTxns(txns, idxSet) }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search transactions")
            .navigationTitle("History")
            .background(Color(.systemGroupedBackground))
        }
    }

    private func statChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @Environment(\.modelContext) private var ctx
    private func deleteTxns(_ txns: [Transaction], _ idxSet: IndexSet) {
        for i in idxSet { ctx.delete(txns[i]) }
        try? ctx.save()
    }
}
