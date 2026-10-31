//
//  SecurityView.swift
//  Spendly copy
//
//  Created by Qi on 3/14/26.
//


import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")
    var isDark: Bool { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var cardBg:    Color { isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.85) }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.35) }

    @State private var showLockSetup   = false
    @State private var showDisableAlert = false
    @State private var appLockEnabled  = false   // 本地 @State，从 AppLockManager 同步

    private var lockManager: AppLockManager { AppLockManager.shared }
    private var phone: String { userStore.phone }
    private var appLockOn: Bool { appLockEnabled }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        NavigationLink {
                            ResetPasswordView()
                                .environmentObject(userStore)
                                .environmentObject(appSettings)
                        } label: {
                            rowChevron(title: t("reset_password"))
                        }
                        .buttonStyle(.plain).padding(.top, 14)

                        // App Lock 行 — 点击而非 toggle
                        appLockRow

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 18)
                }
            }
            BottomBarView(bg: bg, accent: accent, active: .profile, onHome: {}, onPlus: {}, onProfile: {})
        }
        .navigationBarHidden(true)
        .preferredColorScheme(isDark ? .dark : .light)
        .onAppear { appLockEnabled = lockManager.isEnabled(for: phone) }

        // 设置/修改 pin
        .fullScreenCover(isPresented: $showLockSetup) {
            appLockEnabled = lockManager.isEnabled(for: phone)
        } content: {
            AppLockSetupView(isChanging: lockManager.hasPin(for: phone))
                .environmentObject(appSettings)
                .environmentObject(userStore)
        }

        // 关闭 app lock 确认
        .alert(t("disable_app_lock"), isPresented: $showDisableAlert) {
            Button(t("disable"), role: .destructive) {
                lockManager.disable(for: phone)
                appLockEnabled = false
            }
            Button(t("cancel"), role: .cancel) {}
        } message: {
            Text(t("disable_app_lock_confirm"))
        }
    }

    // MARK: - App Lock Row
    private var appLockRow: some View {
        VStack(spacing: 0) {
            // 上半：开关行
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("app_lock")).font(.system(size: 18)).foregroundColor(textColor)
                    Text(appLockOn ? t("app_lock_on") : t("app_lock_off"))
                        .font(.system(size: 12)).foregroundColor(appLockOn ? accent : subColor)
                }
                Spacer()
                ZStack(alignment: appLockOn ? .trailing : .leading) {
                    Capsule().fill(appLockOn ? accent : Color.black.opacity(0.15)).frame(width: 52, height: 30)
                    Circle().fill(.white).frame(width: 24, height: 24).padding(3)
                }
                .onTapGesture { handleAppLockTap() }
            }
            .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, appLockOn ? 12 : 18)

            // 하반：Change PIN（只在已开启时显示）
            if appLockOn {
                Divider().opacity(0.12).padding(.horizontal, 16)
                Button { showLockSetup = true } label: {
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.system(size: 14)).foregroundColor(accent)
                        Text(t("change_pin"))
                            .font(.system(size: 15, weight: .medium)).foregroundColor(accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(subColor)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
        .animation(.spring(response: 0.3), value: appLockOn)
    }

    private func handleAppLockTap() {
        if appLockOn {
            // 已开启 → 确认关闭
            showDisableAlert = true
        } else {
            // 未开启 → 弹设置流程
            showLockSetup = true
        }
    }

    // MARK: - Common rows
    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(textColor)
                }
                Text(t("security")).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }.background(bg.ignoresSafeArea(edges: .top))
    }

    private func rowChevron(title: String) -> some View {
        HStack {
            Text(title).font(.system(size: 18)).foregroundColor(textColor)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(subColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private func rowToggle(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(.system(size: 18)).foregroundColor(textColor)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(accent)
        }
        .padding(.horizontal, 16).padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    NavigationStack {
        SecurityView()
            .environmentObject(AppSettings())
            .environmentObject(UserStore())
    }
}
