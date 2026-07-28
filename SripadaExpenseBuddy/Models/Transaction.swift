import SwiftData
import Foundation

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var isExpense: Bool
    var category: String
    var note: String
    var date: Date

    init(amount: Double, isExpense: Bool, category: String, note: String = "", date: Date = .now) {
        self.id = UUID()
        self.amount = amount
        self.isExpense = isExpense
        self.category = category
        self.note = note
        self.date = date
    }
}
