import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var appSettings: AppSettings

    private let accent = Color(hex: "7E6AD6")

    var isDark: Bool { colorScheme == .dark }
    var bg:           Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var cardBg:       Color { isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.85) }
    var textColor:    Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:     Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.55) }
    var iconColor:    Color { isDark ? Color.white.opacity(0.65) : Color.black.opacity(0.65) }
    var chevronColor: Color { isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.35) }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 18) {
                headerCard.padding(.horizontal, 18).padding(.top, 18)
                menuList.padding(.horizontal, 18)
                Spacer().frame(height: 120)
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(cardBg).frame(width: 62, height: 62)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                if let img = userStore.avatarImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 62, height: 62).clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 26, weight: .semibold)).foregroundColor(accent.opacity(0.7))
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(userStore.username).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Text(userStore.phone).font(.system(size: 15)).foregroundColor(subColor)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(isDark ? 0.08 : 0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 10)
    }

    private var menuList: some View {
        VStack(spacing: 12) {
            NavigationLink { PersonalInformationView().environmentObject(userStore) } label: {
                menuRow(icon: "person", title: t("personal_info"))
            }
            NavigationLink { SecurityView().environmentObject(userStore) } label: {
                menuRow(icon: "shield", title: t("security"))
            }
            NavigationLink { SettingsView().environmentObject(appSettings).environmentObject(userStore) } label: {
                menuRow(icon: "gearshape", title: t("settings"))
            }
            NavigationLink { AboutView() } label: {
                menuRow(icon: "info.circle", title: t("about"))
            }
        }
        .buttonStyle(.plain)
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(iconColor).frame(width: 28)
            Text(title).font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundColor(chevronColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(isDark ? 0.08 : 0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
    }
}

#Preview("Profile + BottomBar") {
    PreviewWithBottomBar(active: .profile) {
        ProfileView()
            .environmentObject(UserStore())
            .environmentObject(AppSettings())
    }
}
