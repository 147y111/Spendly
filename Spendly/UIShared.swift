import SwiftUI

// ===============================
// Shared helpers (DEFINE ONCE)
// ===============================

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// ===============================
// Bottom Bar
// ===============================

struct BottomBarView: View {
    var bg: Color = Color(hex: "FFFAFA")
    var accent: Color = Color(hex: "7E6AD6")
    var plusBg: Color = Color(hex: "DCCAF6")

    enum ActiveTab { case home, add, analytics, profile }
    var active: ActiveTab = .home

    var onHome:      () -> Void = {}
    var onPlus:      () -> Void = {}
    var onAnalytics: () -> Void = {}
    var onProfile:   () -> Void = {}

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(bg)
                    .frame(height: 92)
                    .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: -6)

                HStack(spacing: 0) {
                    tabButton(icon: "house",     filled: "house.fill",      tab: .home,      action: onHome)
                    tabButton(icon: "plus",      filled: "plus.circle.fill", tab: .add,       action: onPlus)
                    tabButton(icon: "chart.bar", filled: "chart.bar.fill",   tab: .analytics, action: onAnalytics)
                    tabButton(icon: "person",    filled: "person.fill",      tab: .profile,   action: onProfile)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 2)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 2)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func tabButton(icon: String, filled: String, tab: ActiveTab, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: active == tab ? filled : icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(active == tab ? accent : accent.opacity(0.30))
                .scaleEffect(active == tab ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: active)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// ===============================
// Preview helper (你报错缺这个)
// ===============================

struct PreviewWithBottomBar<Content: View>: View {
    let active: BottomBarView.ActiveTab
    let content: Content

    init(active: BottomBarView.ActiveTab, @ViewBuilder content: () -> Content) {
        self.active = active
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
            BottomBarView(active: active)
        }
    }
}

// ===============================
// Dismiss overlay helper (你报错缺这个)
// ===============================

struct DismissButtonOverlay: View {
    var title: String
    var onBack: () -> Void

    // Make sure your Color hex extension is available in the project
    private let bg = Color(hex: "FFFAFA")

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black.opacity(0.85))
                        // Added a content shape to make the tap area larger
                        .contentShape(Rectangle())
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black.opacity(0.85))
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14) // Balanced padding

            Divider().opacity(0.15)
        }
        .background(bg.ignoresSafeArea(edges: .top)) // Ensures color goes to the very top
    }
}
