import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let onAdd: () -> Void

    private let items: [(icon: String, label: String, tag: Int)] = [
        ("house.fill",          "Home",     0),
        ("clock.fill",          "History",  1),
        ("plus",                "",         2),
        ("chart.bar.fill",      "Reports",  3),
        ("gearshape.fill",      "Settings", 4),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                if item.tag == 2 {
                    // Centre FAB
                    Button(action: onAdd) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.gradient)
                                .frame(width: 56, height: 56)
                                .shadow(color: AppTheme.violet.opacity(0.4), radius: 8, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -18)
                    .frame(maxWidth: .infinity)
                } else {
                    Button {
                        selectedTab = item.tag
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: item.icon)
                                .font(.system(size: selectedTab == item.tag ? 22 : 20))
                                .symbolRenderingMode(.hierarchical)
                            if !item.label.isEmpty {
                                Text(item.label)
                                    .font(.caption2)
                                    .fontWeight(selectedTab == item.tag ? .bold : .regular)
                            }
                        }
                        .foregroundColor(selectedTab == item.tag ? AppTheme.violet : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
