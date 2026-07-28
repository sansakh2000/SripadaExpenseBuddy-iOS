import SwiftData
import Foundation

@Model
final class RecurringItem {
    var id: UUID
    var name: String
    var amount: Double
    var isExpense: Bool
    var category: String
    var dueDayOfMonth: Int  // 1–31
    var isActive: Bool
    var isEMI: Bool
    var totalMonths: Int    // for EMI; 0 = indefinite
    var paidMonths: Int

    init(name: String, amount: Double, isExpense: Bool = true, category: String = "Bills",
         dueDayOfMonth: Int = 1, isEMI: Bool = false, totalMonths: Int = 0) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.isExpense = isExpense
        self.category = category
        self.dueDayOfMonth = dueDayOfMonth
        self.isActive = true
        self.isEMI = isEMI
        self.totalMonths = totalMonths
        self.paidMonths = 0
    }

    var nextDueDate: Date {
        var comps = Calendar.current.dateComponents([.year, .month], from: .now)
        comps.day = dueDayOfMonth
        let candidate = Calendar.current.date(from: comps) ?? .now
        if candidate < .now {
            return Calendar.current.date(byAdding: .month, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }
}
