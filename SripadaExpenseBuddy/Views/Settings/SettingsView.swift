import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var showPaywall: Bool
    @Query private var transactions: [Transaction]
    @AppStorage("appLanguage") private var language = "English"
    @State private var showBackupAlert = false
    @State private var backupDone = false

    private let languages = ["English", "हिंदी", "मराठी"]

    var body: some View {
        NavigationStack {
            Form {
                // Language
                Section("Language") {
                    Picker("Language", selection: $language) {
                        ForEach(languages, id: \.self) { Text($0).tag($0) }
                    }
                }

                // Subscription
                Section("Subscription") {
                    Button { showPaywall = true } label: {
                        HStack {
                            Label("Go Pro", systemImage: "crown.fill").foregroundColor(AppTheme.gold)
                            Spacer()
                            Text("₹69/mo · ₹499/yr")
                                .font(.caption).foregroundColor(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    Text("✓ Remove ads  ✓ AI Analytics  ✓ PDF Export")
                        .font(.caption).foregroundColor(.secondary)
                }

                // Backup
                Section("Backup & Restore") {
                    Button {
                        exportBackup()
                    } label: {
                        Label("Back Up Now", systemImage: "icloud.and.arrow.up")
                    }

                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export Records", systemImage: "square.and.arrow.up")
                    }
                }

                // Data
                Section("Data") {
                    HStack {
                        Label("Total Transactions", systemImage: "list.bullet")
                        Spacer()
                        Text("\(transactions.count)").foregroundColor(.secondary)
                    }
                    NavigationLink {
                        MoneyTrackerView()
                    } label: {
                        Label("Money Tracker", systemImage: "person.2.fill")
                    }
                    NavigationLink {
                        RecurringView()
                    } label: {
                        Label("Recurring & EMI", systemImage: "arrow.clockwise")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0 (1)").foregroundColor(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://sansakh2000.github.io/SripadaExpenseBuddy-iOS/privacy.html")!)
                    Link("Support / Contact", destination: URL(string: "mailto:sansakh2000@gmail.com")!)
                }
            }
            .navigationTitle("Settings")
            .alert("Backup saved!", isPresented: $backupDone) {
                Button("OK") {}
            }
        }
    }

    private func exportBackup() {
        // Simple JSON backup
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try? encoder.encode(transactions.map { t in
            ["id": t.id.uuidString, "amount": "\(t.amount)", "isExpense": "\(t.isExpense)",
             "category": t.category, "note": t.note,
             "date": ISO8601DateFormatter().string(from: t.date)] as [String: String]
        })
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sripada_backup.json")
        try? data?.write(to: url)
        backupDone = true
    }
}
