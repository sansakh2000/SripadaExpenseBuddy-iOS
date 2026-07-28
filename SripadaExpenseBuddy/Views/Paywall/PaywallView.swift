import SwiftUI
import StoreKit

struct PaywallView: View {
    let onDismiss: () -> Void
    @StateObject private var store = StoreManager()
    @State private var selectedPlan = "yearly"
    @State private var isPurchasing = false

    private let features: [(String, String, String)] = [
        ("🚫", "Ad-Free Experience",    "No more ads, ever"),
        ("✨", "AI Analytics",          "Spending insights powered by AI"),
        ("📊", "Advanced Reports",      "Year-over-year deep analysis"),
        ("📅", "Cash Flow Calendar",    "30-day payment forecasting"),
        ("🏆", "Savings Challenges",    "Goal-based saving streaks"),
        ("📄", "PDF Export",            "Full reports as PDF"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    ZStack {
                        AppTheme.heroGradient.ignoresSafeArea(edges: .top)
                        VStack(spacing: 12) {
                            ZStack {
                                Circle().fill(.white.opacity(0.15)).frame(width: 80, height: 80)
                                Text("👑").font(.system(size: 40))
                            }
                            Text("Sripada Pro")
                                .font(.largeTitle.bold()).foregroundColor(.white)
                            Text("Unlock every feature, remove all ads.")
                                .font(.subheadline).foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 20) {
                        // Plan cards
                        VStack(spacing: 10) {
                            Text("Choose Your Plan").font(.headline).frame(maxWidth: .infinity, alignment: .leading)

                            PlanCardView(
                                selected: selectedPlan == "yearly",
                                badge: "BEST VALUE — Save 40%",
                                title: "Annual Plan",
                                price: store.yearlyPrice ?? "₹499",
                                period: "/ year",
                                detail: "Just ₹41/month"
                            ) { selectedPlan = "yearly" }

                            PlanCardView(
                                selected: selectedPlan == "monthly",
                                badge: nil,
                                title: "Monthly Plan",
                                price: store.monthlyPrice ?? "₹69",
                                period: "/ month",
                                detail: "Cancel anytime"
                            ) { selectedPlan = "monthly" }
                        }
                        .padding(.horizontal)

                        // CTA
                        if isPurchasing {
                            ProgressView().tint(AppTheme.violet)
                        } else {
                            Button {
                                Task { await purchase() }
                            } label: {
                                Text("Subscribe Now →")
                                    .font(.headline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.gradient)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.horizontal)
                        }

                        Text("Subscriptions auto-renew. Cancel anytime in App Store.")
                            .font(.caption).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Divider().padding(.horizontal)

                        // Feature list
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Everything in Pro").font(.headline)
                            ForEach(features, id: \.0) { emoji, title, subtitle in
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppTheme.violet.opacity(0.1)).frame(width: 40, height: 40)
                                        Text(emoji).font(.title3)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(title).font(.subheadline.bold())
                                        Text(subtitle).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        Button("Restore Purchases") {
                            Task { try? await AppStore.sync() }
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.violet)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onDismiss() } label: { Image(systemName: "xmark").fontWeight(.semibold) }
                }
            }
        }
        .task { await store.loadProducts() }
    }

    private func purchase() async {
        isPurchasing = true
        let productId = selectedPlan == "yearly"
            ? StoreManager.yearlyProductId
            : StoreManager.monthlyProductId
        await store.purchase(productId: productId)
        isPurchasing = false
        if store.isPro { onDismiss() }
    }
}

struct PlanCardView: View {
    let selected: Bool
    let badge: String?
    let title: String
    let price: String
    let period: String
    let detail: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundColor(Color(red:0.24,green:0.15,blue:0))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline)
                        Text(detail).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    (Text(price).font(.title2.bold()) + Text(period).font(.caption).foregroundColor(.secondary))
                        .foregroundColor(selected ? AppTheme.violet : .primary)
                }
            }
            .padding(16)
            .background(selected ? AppTheme.violet.opacity(0.06) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? AppTheme.violet : Color(.separator), lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StoreKit Manager
@MainActor
class StoreManager: ObservableObject {
    static let monthlyProductId = "com.sripada.expensebuddy.monthly"
    static let yearlyProductId  = "com.sripada.expensebuddy.yearly"

    @Published var isPro         = false
    @Published var monthlyPrice: String?
    @Published var yearlyPrice:  String?

    private var products: [Product] = []

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.monthlyProductId, Self.yearlyProductId])
            for p in products {
                if p.id == Self.monthlyProductId { monthlyPrice = p.displayPrice }
                if p.id == Self.yearlyProductId  { yearlyPrice  = p.displayPrice }
            }
            await checkEntitlement()
        } catch {
            print("StoreKit load error:", error)
        }
    }

    func purchase(productId: String) async {
        guard let product = products.first(where: { $0.id == productId }) else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    isPro = true
                }
            default: break
            }
        } catch {
            print("Purchase error:", error)
        }
    }

    private func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let txn) = result,
               [Self.monthlyProductId, Self.yearlyProductId].contains(txn.productID) {
                isPro = true
                return
            }
        }
    }
}
