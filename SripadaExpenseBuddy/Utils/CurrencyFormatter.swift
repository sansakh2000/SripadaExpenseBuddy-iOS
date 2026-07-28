import Foundation

enum CurrencyFormatter {
    static let inr: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        f.currencySymbol = "₹"
        f.maximumFractionDigits = 0
        return f
    }()

    static func format(_ value: Double) -> String {
        inr.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
    }

    static func compact(_ value: Double) -> String {
        if value >= 100_000 { return "₹\(String(format: "%.1f", value/100_000))L" }
        if value >= 1_000   { return "₹\(String(format: "%.1f", value/1_000))K" }
        return format(value)
    }
}
