import SwiftUI

struct MainRootView: View {
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var lm = LocalizationManager.shared
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var ledgerStore: LedgerStore

    private let accent = Color(hex: "7E6AD6")
    private let plusBg = Color(hex: "DCCAF6")

    enum Tab { case home, add, analytics, profile }
    @State private var tab: Tab = .home

    var bg: Color {
        appSettings.isDarkMode ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA")
    }

    var barBg: Color {
        appSettings.isDarkMode ? Color(hex: "2C2C2E") : Color(hex: "FFFAFA")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            bg.ignoresSafeArea()

            Group {
                switch tab {
                case .home:
                    DashboardView()
                        .environmentObject(ledgerStore)
                        .environmentObject(appSettings)

                case .add:
                    AddEntryView(onSaveComplete: { tab = .home })
                        .environmentObject(ledgerStore)
                        .environmentObject(userStore)
                        .environmentObject(appSettings)

                case .analytics:
                    AnalyticsView()
                        .environmentObject(ledgerStore)
                        .environmentObject(appSettings)

                case .profile:
                    ProfileRootView()
                        .environmentObject(userStore)
                        .environmentObject(appSettings)
                }
            }

            BottomBarView(
                bg: barBg,
                accent: accent,
                plusBg: plusBg,
                active: mapToActiveTab(tab),
                onHome: { tab = .home },
                onPlus: { tab = .add },
                onAnalytics: { tab = .analytics },
                onProfile: { tab = .profile }
            )
        }
        .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
    }

    private func mapToActiveTab(_ t: Tab) -> BottomBarView.ActiveTab {
        switch t {
        case .home: return .home
        case .add: return .add
        case .analytics: return .analytics
        case .profile: return .profile
        }
    }
}

#Preview {
    let userStore = UserStore(phone: "1234567890")
    let ledgerStore = LedgerStore(userStore: userStore)

    return MainRootView()
        .environmentObject(AppSettings())
        .environmentObject(userStore)
        .environmentObject(ledgerStore)
}
