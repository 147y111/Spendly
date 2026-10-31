import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings

    private let accent = Color(hex: "7E6AD6")

    var isDark:    Bool  { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var cardBg:    Color { isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.85) }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.45) }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // App icon + name
                        VStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(accent.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Text("💜").font(.system(size: 44))
                            }
                            Text("Spendly")
                                .font(.system(size: 26, weight: .bold)).foregroundColor(textColor)
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.system(size: 14)).foregroundColor(subColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(RoundedRectangle(cornerRadius: 20).fill(cardBg))
                        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
                        .padding(.top, 14)

                        // Info rows
                        infoRow(icon: "doc.text", title: t("about_description_title"),
                                value: t("about_description"))
                        infoRow(icon: "paintpalette", title: t("about_design_title"),
                                value: t("about_design"))
                        infoRow(icon: "lock.shield", title: t("about_privacy_title"),
                                value: t("about_privacy"))

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 18)
                }
            }
            BottomBarView(bg: bg, accent: accent, active: .profile, onHome: {}, onPlus: {}, onProfile: {})
        }
        .navigationBarHidden(true)
        .preferredColorScheme(isDark ? .dark : .light)
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(textColor)
                }
                Text(t("about")).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }
        .background(bg.ignoresSafeArea(edges: .top))
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .medium)).foregroundColor(subColor)
                Text(value).font(.system(size: 16)).foregroundColor(textColor)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
    }
}

#Preview { NavigationStack { AboutView().environmentObject(AppSettings()) } }
