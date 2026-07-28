import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAddTransaction = false
    @State private var showPaywall = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(showAddTransaction: $showAddTransaction, showPaywall: $showPaywall)
                    .tag(0)
                TransactionHistoryView()
                    .tag(1)
                Color.clear.tag(2)   // placeholder for center FAB
                ReportsView()
                    .tag(3)
                SettingsView(showPaywall: $showPaywall)
                    .tag(4)
            }
            .tabViewStyle(.automatic)
            .overlay(alignment: .bottom) {
                FloatingTabBar(selectedTab: $selectedTab, onAdd: { showAddTransaction = true })
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(onDismiss: { showPaywall = false })
        }
    }
}
