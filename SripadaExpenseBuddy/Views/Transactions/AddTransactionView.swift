import SwiftUI
import SwiftData
import Speech
import AVFoundation

struct AddTransactionView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss)      private var dismiss

    @State private var isExpense    = true
    @State private var amountText   = ""
    @State private var selectedCat  = ""
    @State private var note         = ""
    @State private var date         = Date()
    @State private var showVoice    = false
    @State private var saved        = false

    private var categories: [CategoryInfo] { isExpense ? expenseCategories : incomeCategories }
    private var amount: Double { Double(amountText) ?? 0 }
    private var canSave: Bool { amount > 0 && !selectedCat.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                // Type toggle
                Section {
                    Picker("Type", selection: $isExpense) {
                        Text("Expense").tag(true)
                        Text("Income").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isExpense) { _, _ in selectedCat = "" }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
                .padding(.horizontal)

                // Amount
                Section("Amount") {
                    HStack {
                        Text("₹").font(.title2.bold()).foregroundColor(AppTheme.violet)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                    }
                }

                // Category
                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        ForEach(categories, id: \.name) { cat in
                            CategoryPill(info: cat, selected: selectedCat == cat.name) {
                                selectedCat = cat.name
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Note & date
                Section("Details") {
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                // Voice entry shortcut
                Section {
                    Button { showVoice = true } label: {
                        Label("Use Voice Entry instead", systemImage: "mic.fill")
                            .foregroundColor(AppTheme.violet)
                    }
                }
            }
            .navigationTitle(isExpense ? "Add Expense" : "Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showVoice) {
                VoiceEntryView { result in
                    applyVoiceResult(result)
                    showVoice = false
                }
            }
            .overlay {
                if saved {
                    SavedConfirmation()
                }
            }
        }
    }

    private func save() {
        let txn = Transaction(amount: amount, isExpense: isExpense, category: selectedCat, note: note, date: date)
        ctx.insert(txn)
        try? ctx.save()
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
    }

    private func applyVoiceResult(_ result: VoiceResult) {
        amountText = result.amount > 0 ? String(format: "%.0f", result.amount) : amountText
        if !result.category.isEmpty { selectedCat = result.category }
        if !result.note.isEmpty     { note = result.note }
        isExpense = result.isExpense
    }
}

struct CategoryPill: View {
    let info: CategoryInfo
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(info.emoji).font(.title3)
                Text(info.name)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(selected ? info.color.opacity(0.18) : Color(.systemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(selected ? info.color : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundColor(selected ? info.color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

struct SavedConfirmation: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.incomeGreen)
            Text("Saved!").font(.headline)
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .transition(.scale.combined(with: .opacity))
    }
}
