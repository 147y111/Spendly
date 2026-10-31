import SwiftUI

struct PersonalInformationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")

    var isDark: Bool { colorScheme == .dark }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var cardBg:    Color { isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.85) }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.55) }

    // 判断是否已绑定邮箱/手机
    var hasEmail: Bool { !userStore.email.isEmpty }
    var hasPhone: Bool { !userStore.phone.isEmpty && userStore.phone != "guest" }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar(title: t("personal_info"))
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerCard.padding(.horizontal, 18).padding(.top, 14)
                        VStack(spacing: 12) {
                            NavigationLink {
                                ChangeUsernameView().environmentObject(userStore)
                            } label: { row(title: t("change_username")) }

                            NavigationLink {
                                ChangeAvatarView().environmentObject(userStore)
                            } label: { row(title: t("change_avatar")) }

                            // 邮箱：有就修改，没有就绑定
                            NavigationLink {
                                ChangeEmailView().environmentObject(userStore)
                            } label: {
                                row(title: hasEmail ? t("change_email") : t("bind_email"),
                                    subtitle: hasEmail ? userStore.email : nil)
                            }

                        }
                        .buttonStyle(.plain).padding(.horizontal, 18)
                        Spacer().frame(height: 120)
                    }
                }
            }
            BottomBarView(bg: bg, accent: accent, active: .profile, onHome: {}, onPlus: {}, onProfile: {})
        }
        .navigationBarHidden(true)
    }

    private func topBar(title: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(textColor)
                }
                Text(title).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }
        .background(bg.ignoresSafeArea(edges: .top))
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(cardBg).frame(width: 62, height: 62)
                if let img = userStore.avatarImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 62, height: 62).clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 26, weight: .semibold)).foregroundColor(accent.opacity(0.65))
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(userStore.username).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                if hasPhone {
                    Text(userStore.phone).font(.system(size: 15)).foregroundColor(subColor)
                } else if hasEmail {
                    Text(userStore.email).font(.system(size: 15)).foregroundColor(subColor)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardBg))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 10)
    }

    private func row(title: String, subtitle: String? = nil) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 17)).foregroundColor(textColor)
                if let sub = subtitle {
                    Text(sub).font(.system(size: 13)).foregroundColor(subColor)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(subColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardBg))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    NavigationStack { PersonalInformationView().environmentObject(UserStore()) }
}
