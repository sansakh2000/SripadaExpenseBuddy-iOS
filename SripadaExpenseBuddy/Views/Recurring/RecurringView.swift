import SwiftUI
import SwiftData

struct RecurringView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \RecurringItem.dueDayOfMonth) private var items: [RecurringItem]
    @State private var showAdd = false
    @State private var tab = 0  // 0 = All, 1 = EMI, 2 = Others

    private var active: [RecurringItem] { items.filter { $0.isActive } }
    private var shown: [RecurringItem] {
        switch tab {
        case 1: return active.filter { $0.isEMI }
        case 2: return active.filter { !$0.isEMI }
        default: return active
        }
    }

    private var monthlyOut: Double { active.filter {  $0.isExpense }.reduce(0) { $0 + $1.amount } }
    private var monthlyIn:  Double { active.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                summaryBox("Monthly Out", monthlyOut, AppTheme.expenseRed)
                summaryBox("Monthly In",  monthlyIn,  AppTheme.incomeGreen)
            }
            .padding()

            Picker("", selection: $tab) {
                Text("All").tag(0); Text("EMI / Loans").tag(1); Text("Others").tag(2)
            }
            .pickerStyle(.segmented).padding(.horizontal)

            if shown.isEmpty {
                ContentUnavailableView("No recurring items", systemImage: "arrow.clockwise",
                    description: Text("Tap + to add EMIs, subscriptions, or salary."))
            } else {
                List {
                    ForEach(shown) { item in RecurringRow(item: item) }
                        .onDelete { idxSet in
                            for i in idxSet { shown[i].isActive = false }
                            try? ctx.save()
                        }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Recurring & EMI")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { AddRecurringView() }
        .background(Color(.systemGroupedBackground))
    }

    private func summaryBox(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(CurrencyFormatter.format(value)).font(.title3.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity).padding()
        .background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct RecurringRow: View {
    let item: RecurringItem
    private var info: CategoryInfo { categoryInfo(for: item.category) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(info.color.opacity(0.15)).frame(width: 42, height: 42)
                Text(info.emoji).font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline.bold())
                Text("Due \(ordinal(item.dueDayOfMonth)) · every month")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text((item.isExpense ? "-" : "+") + CurrencyFormatter.format(item.amount))
                .font(.subheadline.bold())
                .foregroundColor(item.isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen)
        }
        .padding(12).cardStyle()
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    private func ordinal(_ n: Int) -> String {
        let s = ["th","st","nd","rd"]
        let v = n % 100
        return "\(n)\(s[(v - 20 % 20) < 4 ? (v - 20) % 20 : min(v < 4 ? v : 0, 3)])"
    }
}

struct AddRecurringView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""; @State private var amtText = ""
    @State private var isExpense = true; @State private var isEMI = false
    @State private var category = "Bills"; @State private var dueDay = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Direction", selection: $isExpense) {
                        Text("Expense").tag(true); Text("Income").tag(false)
                    }.pickerStyle(.segmented)
                    Toggle("Is this an EMI / Loan?", isOn: $isEMI)
                }
                Section("Details") {
                    TextField("Name (e.g. House EMI)", text: $name)
                    HStack {
                        Text("₹").font(.title2.bold()).foregroundColor(AppTheme.violet)
                        TextField("0", text: $amtText).keyboardType(.decimalPad)
                    }
                }
                Section("Due Day") {
                    Stepper("Due on the \(dueDay)\(suffix(dueDay))", value: $dueDay, in: 1...28)
                }
            }
            .navigationTitle("Add Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let r = RecurringItem(name: name, amount: Double(amtText) ?? 0,
                                             isExpense: isExpense, category: category,
                                             dueDayOfMonth: dueDay, isEMI: isEMI)
                        ctx.insert(r); try? ctx.save(); dismiss()
                    }
                    .disabled(name.isEmpty || (Double(amtText) ?? 0) <= 0).fontWeight(.bold)
                }
            }
        }
    }
    private func suffix(_ n: Int) -> String { ["st","nd","rd"].indices.contains(n-1) && n <= 3 ? ["st","nd","rd"][n-1] : "th" }
}
