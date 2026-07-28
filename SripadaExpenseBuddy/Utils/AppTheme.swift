import SwiftUI

enum AppTheme {
    static let violet       = Color(red: 0.38, green: 0.14, blue: 0.91)
    static let teal         = Color(red: 0.05, green: 0.58, blue: 0.53)
    static let gold         = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let incomeGreen  = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let expenseRed   = Color(red: 0.97, green: 0.44, blue: 0.44)

    static var gradient: LinearGradient {
        LinearGradient(colors: [violet, teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var heroGradient: LinearGradient {
        LinearGradient(colors: [Color(red:0.30,green:0.11,blue:0.58), teal],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
