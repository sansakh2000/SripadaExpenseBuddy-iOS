import SwiftUI
import SwiftData

struct MoneyTrackerView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \LendBorrow.date, order: .reverse) private var items: [LendBorrow]
    @State private var showAdd   = false
    @State private var tab       = 0    // 0 = Lent, 1 = Borrowed

    private var lent:     [LendBorrow] { items.filter {  $0.isLent && !$0.isPaid } }
    private var borrowed: [LendBorrow] { items.filter { !$0.isLent && !$0.isPaid } }
    private var shown:    [LendBorrow] { tab == 0 ? lent : borrowed }
    private var netOwed:  Double { lent.reduce(0) { $0 + $1.amount } - borrowed.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(spacing: 0) {
            // Summary strip
            HStack(spacing: 12) {
                summaryBox("I Lent", lent.reduce(0) { $0 + $1.amount }, AppTheme.teal)
                summaryBox("I Borrowed", borrowed.reduce(0) { $0 + $1.amount }, AppTheme.expenseRed)
            }
            .padding()

            if netOwed != 0 {
                HStack {
                    Image(systemName: netOwed > 0 ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                    Text(netOwed > 0
                         ? "Others owe you \(CurrencyFormatter.format(netOwed))"
                         : "You owe others \(CurrencyFormatter.format(abs(netOwed)))")
                        .font(.subheadline.bold())
                }
                .foregroundColor(netOwed > 0 ? AppTheme.incomeGreen : AppTheme.expenseRed)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Picker("", selection: $tab) {
                Text("I Lent (\(lent.count))").tag(0)
                Text("I Borrowed (\(borrowed.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if shown.isEmpty {
                ContentUnavailableView(
                    tab == 0 ? "No pending lendings" : "No pending borrowings",
                    systemImage: tab == 0 ? "arrow.up.right" : "arrow.down.left",
                    description: Text("Tap + to track money you \(tab == 0 ? "lent" : "borrowed").")
                )
            } else {
                List {
                    ForEach(shown) { item in
                        LendBorrowRow(item: item) {
                            item.isPaid = true
                            try? ctx.save()
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Money Tracker")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { AddLendBorrowView(defaultIsLent: tab == 0) }
        .background(Color(.systemGroupedBackground))
    }

    private func summaryBox(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(CurrencyFormatter.format(value)).font(.title3.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct LendBorrowRow: View {
    let item: LendBorrow
    let onMarkPaid: () -> Void

    private var avatar: String { String(item.personName.prefix(1).uppercased()) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(item.isLent ? AppTheme.teal.opacity(0.2) : AppTheme.expenseRed.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(avatar).font(.headline.bold())
                    .foregroundColor(item.isLent ? AppTheme.teal : AppTheme.expenseRed)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.personName).font(.subheadline.bold())
                if let due = item.dueDate {
                    Text("Due \(due.formatted(.dateTime.day().month(.abbreviated)))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(item.amount))
                    .font(.subheadline.bold())
                    .foregroundColor(item.isLent ? AppTheme.teal : AppTheme.expenseRed)
                Button("Mark Paid") { onMarkPaid() }
                    .font(.caption2).foregroundColor(AppTheme.violet)
            }
        }
        .padding(12)
        .cardStyle()
    }
}

struct AddLendBorrowView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss)      private var dismiss
    var defaultIsLent: Bool

    @State private var isLent    = true
    @State private var name      = ""
    @State private var amtText   = ""
    @State private var hasDue    = false
    @State private var dueDate   = Date()
    @State private var note      = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $isLent) {
                    Text("I Lent").tag(true)
                    Text("I Borrowed").tag(false)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                Section("Person") {
                    TextField("Name", text: $name)
                }
                Section("Amount") {
                    HStack {
                        Text("₹").font(.title2.bold()).foregroundColor(AppTheme.violet)
                        TextField("0", text: $amtText).keyboardType(.decimalPad)
                    }
                }
                Section("Due Date (optional)") {
                    Toggle("Set a due date", isOn: $hasDue)
                    if hasDue { DatePicker("Due", selection: $dueDate, displayedComponents: .date) }
                }
                Section("Note") {
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle(isLent ? "Add Lending" : "Add Borrowing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || (Double(amtText) ?? 0) <= 0)
                        .fontWeight(.bold)
                }
            }
        }
        .onAppear { isLent = defaultIsLent }
    }

    private func save() {
        let item = LendBorrow(
            personName: name,
            amount: Double(amtText) ?? 0,
            isLent: isLent,
            dueDate: hasDue ? dueDate : nil,
            note: note
        )
        ctx.insert(item)
        try? ctx.save()
        dismiss()
    }
}
