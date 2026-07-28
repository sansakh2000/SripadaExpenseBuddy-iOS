import SwiftUI

struct CategoryInfo {
    let name: String
    let emoji: String
    let color: Color
}

let expenseCategories: [CategoryInfo] = [
    CategoryInfo(name: "Food & Drinks",  emoji: "🍔", color: .orange),
    CategoryInfo(name: "Groceries",      emoji: "🛒", color: .green),
    CategoryInfo(name: "Transport",      emoji: "🚗", color: .blue),
    CategoryInfo(name: "Shopping",       emoji: "🛍️", color: .pink),
    CategoryInfo(name: "Bills",          emoji: "⚡", color: .yellow),
    CategoryInfo(name: "Health",         emoji: "💊", color: .red),
    CategoryInfo(name: "Education",      emoji: "📚", color: .indigo),
    CategoryInfo(name: "Entertainment",  emoji: "🎬", color: .purple),
    CategoryInfo(name: "Travel",         emoji: "✈️", color: .teal),
    CategoryInfo(name: "EMI / Loan",     emoji: "🏦", color: .brown),
    CategoryInfo(name: "Rent",           emoji: "🏠", color: .mint),
    CategoryInfo(name: "Other",          emoji: "📌", color: .gray),
]

let incomeCategories: [CategoryInfo] = [
    CategoryInfo(name: "Salary",         emoji: "💼", color: .green),
    CategoryInfo(name: "Freelance",      emoji: "💻", color: .blue),
    CategoryInfo(name: "Business",       emoji: "🏪", color: .orange),
    CategoryInfo(name: "Investment",     emoji: "📈", color: .teal),
    CategoryInfo(name: "Gift",           emoji: "🎁", color: .pink),
    CategoryInfo(name: "Refund",         emoji: "↩️", color: .indigo),
    CategoryInfo(name: "Other",          emoji: "📌", color: .gray),
]

func categoryInfo(for name: String) -> CategoryInfo {
    (expenseCategories + incomeCategories).first { $0.name == name }
        ?? CategoryInfo(name: name, emoji: "📌", color: .gray)
}
