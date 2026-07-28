import SwiftData
import Foundation

@Model
final class LendBorrow {
    var id: UUID
    var personName: String
    var amount: Double
    var isLent: Bool        // true = I lent, false = I borrowed
    var date: Date
    var dueDate: Date?
    var note: String
    var isPaid: Bool

    init(personName: String, amount: Double, isLent: Bool, date: Date = .now, dueDate: Date? = nil, note: String = "") {
        self.id = UUID()
        self.personName = personName
        self.amount = amount
        self.isLent = isLent
        self.date = date
        self.dueDate = dueDate
        self.note = note
        self.isPaid = false
    }
}
