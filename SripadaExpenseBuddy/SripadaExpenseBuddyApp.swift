import SwiftUI
import SwiftData

@main
struct SripadaExpenseBuddyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Transaction.self, LendBorrow.self, RecurringItem.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
