import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")
    @AppStorage("spendly_voiceover") private var voiceOverOn: Bool = false

    var bg: Color    { appSettings.isDarkMode ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var rowBg: Color { appSettings.isDarkMode ? Color(hex: "2C2C2E") : Color.white.opacity(0.85) }
    var text: Color  { appSettings.isDarkMode ? .white : .black.opacity(0.85) }
    var sub: Color   { appSettings.isDarkMode ? Color.white.opacity(0.45) : Color.black.opacity(0.40) }

    let allLanguages: [AppLanguage] = AppLanguage.allCases
    @State private var showLanguage    = false
    @State private var showLogout      = false
    @State private var showDeleteAcct  = false

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        // ── 外观 ──
                        HStack(spacing: 14) {
                            iconBox(symbol: appSettings.isDarkMode ? "moon.fill" : "sun.max.fill")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t("appearance")).font(.system(size: 17, weight: .medium)).foregroundColor(text)
                                Text(appSettings.isDarkMode ? t("dark_mode") : t("light_mode")).font(.system(size: 12)).foregroundColor(sub)
                            }
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) { appSettings.isDarkMode.toggle() }
                            } label: {
                                ZStack(alignment: appSettings.isDarkMode ? .trailing : .leading) {
                                    Capsule().fill(appSettings.isDarkMode ? accent : Color.black.opacity(0.15)).frame(width: 52, height: 30)
                                    Circle().fill(.white).frame(width: 24, height: 24).padding(3)
                                }
                            }.buttonStyle(.plain)
                        }
                        .rowStyle(bg: rowBg)

                        // ── 语言 ──
                        Button { showLanguage = true } label: {
                            HStack(spacing: 14) {
                                iconBox(symbol: "globe")
                                Text(t("language")).font(.system(size: 17, weight: .medium)).foregroundColor(text)
                                Spacer()
                                Text(appSettings.language.flag + " " + appSettings.language.nativeName)
                                    .font(.system(size: 14, weight: .medium)).foregroundColor(sub)
                                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(sub)
                            }
                        }
                        .buttonStyle(.plain).rowStyle(bg: rowBg)

                        // ── 无障碍 ──
                        HStack(spacing: 14) {
                            iconBox(symbol: "figure.wave")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t("accessibility")).font(.system(size: 17, weight: .medium)).foregroundColor(text)
                                Text(t("read_aloud")).font(.system(size: 12)).foregroundColor(sub)
                            }
                            Spacer()
                            Toggle("", isOn: $voiceOverOn).tint(accent).labelsHidden()
                        }
                        .rowStyle(bg: rowBg)

                        if voiceOverOn {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill").foregroundColor(accent).font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(t("voiceover_active")).font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                                    Text(t("voiceover_guide")).font(.system(size: 12)).foregroundColor(sub)
                                    Button(t("open_ios_settings")) {
                                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                                    }.font(.system(size: 12, weight: .semibold)).foregroundColor(accent)
                                }
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(accent.opacity(0.08)))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // ── 账号 分割线 ──
                        HStack(spacing: 10) {
                            Rectangle().fill(Color.gray.opacity(0.20)).frame(height: 1)
                            Text(t("account"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(sub).fixedSize()
                            Rectangle().fill(Color.gray.opacity(0.20)).frame(height: 1)
                        }
                        .padding(.top, 6)

                        // ── 退出登录 ──
                        Button { showLogout = true } label: {
                            HStack(spacing: 14) {
                                iconBox(symbol: "arrow.right.square")
                                Text(t("logout")).font(.system(size: 17, weight: .medium)).foregroundColor(text)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(sub)
                            }
                        }
                        .buttonStyle(.plain).contentShape(Rectangle()).rowStyle(bg: rowBg)

                        // ── 注销账号 ──
                        Button { showDeleteAcct = true } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.red.opacity(0.12)).frame(width: 40, height: 40)
                                    Image(systemName: "trash")
                                        .font(.system(size: 18, weight: .semibold)).foregroundColor(.red)
                                }
                                Text(t("delete_account"))
                                    .font(.system(size: 17, weight: .medium)).foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(Color.red.opacity(0.4))
                            }
                        }
                        .buttonStyle(.plain).contentShape(Rectangle()).rowStyle(bg: rowBg)

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 18).padding(.top, 18)
                    .animation(.easeInOut(duration: 0.25), value: voiceOverOn)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $showLanguage) { languagePage }

        // 退出登录 alert
        .alert(t("logout"), isPresented: $showLogout) {
            Button(t("logout"), role: .destructive) { userStore.signOut() }
            Button(t("cancel"), role: .cancel) {}
        } message: {
            Text(t("logout_confirm"))
        }

        // 注销账号 alert
        .alert(t("delete_account"), isPresented: $showDeleteAcct) {
            Button(t("delete_account"), role: .destructive) { userStore.deleteAccount() }
            Button(t("cancel"), role: .cancel) {}
        } message: {
            Text(t("delete_confirm"))
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(text)
                }
                Text(t("settings")).font(.system(size: 20, weight: .semibold)).foregroundColor(text)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }.background(bg)
    }

    // MARK: - Language Page (sheet)
    private var languagePage: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Button { showLanguage = false } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold)).foregroundColor(text)
                        }
                        Text(t("language")).font(.system(size: 20, weight: .semibold)).foregroundColor(text)
                        Spacer()
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                    Divider().opacity(0.15)
                }.background(bg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(allLanguages, id: \.rawValue) { lang in
                            Button {
                                appSettings.language = lang
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showLanguage = false }
                            } label: {
                                HStack(spacing: 14) {
                                    Text(lang.flag)
                                        .font(.system(size: 26))
                                    Text(lang.nativeName)
                                        .font(.system(size: 17, weight: appSettings.language == lang ? .semibold : .regular))
                                        .foregroundColor(appSettings.language == lang ? accent : text)
                                    Spacer()
                                    if appSettings.language == lang {
                                        Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundColor(accent)
                                    }
                                }
                                .padding(.horizontal, 18).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16)
                                    .fill(appSettings.language == lang ? accent.opacity(0.08) : rowBg))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(appSettings.language == lang ? accent.opacity(0.3) : Color.white.opacity(0.6), lineWidth: 1))
                                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 18)
                }
            }
        }
        .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
    }

    private func iconBox(symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent.opacity(0.12)).frame(width: 40, height: 40)
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).foregroundColor(accent)
        }
    }
}

private extension View {
    func rowStyle(bg: Color) -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(bg))
            .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettings())
            .environmentObject(UserStore())
    }
}
