import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var auth = AuthManager.shared

    private let accent    = Color(hex: "7E6AD6")
    private let accentSub = Color(hex: "DCCAF6")

    @State private var showTitle    = false
    @State private var showSubtitle = false
    @State private var fadeOut      = false
    @State private var showApp      = false
    @State private var sessionID    = UUID()

    // 当前 session 已解锁的 phone（空字符串 = 未解锁）
    // 用 phone 而不是 Bool，避免账号切换后旧的解锁状态污染新账号
    @State private var unlockedPhone: String = ""

    var isDark: Bool { appSettings.isDarkMode }
    var bg:     Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }

    var body: some View {
        Group {
            if showApp {
                if auth.isLoggedIn {
                    // AccountSessionView 用 .id(sessionID) 整体重建，确保账号数据完全隔离
                    AccountSessionView(unlockedPhone: $unlockedPhone)
                        .environmentObject(appSettings)
                        .id(sessionID)
                        // 解锁通知：记录是哪个 phone 解锁的
                        .onReceive(NotificationCenter.default.publisher(
                            for: AppLockManager.didUnlockNotification)) { notif in
                            unlockedPhone = auth.currentUser?.phone ?? ""
                        }
                        // 登出
                        .onChange(of: auth.isLoggedIn) { _, loggedIn in
                            if !loggedIn {
                                AppLockManager.shared.lock()
                                unlockedPhone = ""
                                sessionID = UUID()
                            }
                        }
                        // 账号切换
                        .onChange(of: auth.currentUser?.phone ?? "") { _, _ in
                            AppLockManager.shared.lock()
                            unlockedPhone = ""   // 清除旧账号的解锁状态
                            sessionID = UUID()   // 强制重建 AccountSessionView
                        }
                } else {
                    LoginView()
                        .environmentObject(appSettings)
                        .onReceive(auth.$isLoggedIn) { loggedIn in
                            if loggedIn {
                                AppLockManager.shared.lock()
                                unlockedPhone = ""
                                sessionID = UUID()
                            }
                        }
                }
            } else {
                // 启动动画
                ZStack {
                    bg.ignoresSafeArea()
                    VStack(spacing: 18) {
                        Text("Spendly")
                            .font(customJulee(size: 72))
                            .foregroundColor(accent)
                            .opacity(showTitle ? (fadeOut ? 0 : 1) : 0)
                            .scaleEffect(showTitle ? 1 : 0.95)
                        Text(t("content_view_subtitle"))
                            .font(customJulee(size: 22))
                            .foregroundColor(accentSub)
                            .opacity(showSubtitle ? (fadeOut ? 0 : 1) : 0)
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8))             { showTitle = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeOut(duration: 0.6))         { showSubtitle = true }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.6))       { fadeOut = true }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) { showApp = true }
                }
            }
        }
        .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
    }

    private func customJulee(size: CGFloat) -> Font {
        UIFont(name: "Julee", size: size) != nil
            ? .custom("Julee", size: size)
            : .system(size: size, weight: .regular, design: .rounded)
    }
}

// ================================================
// AccountSessionView
// 每次 sessionID 变化时被整体重建（@StateObject 也重新 init），
// 确保 userStore / ledgerStore 完全属于当前账号
// ================================================

private struct AccountSessionView: View {
    @Binding var unlockedPhone: String

    @EnvironmentObject var appSettings: AppSettings

    @StateObject private var userStore: UserStore
    @StateObject private var ledgerStore: LedgerStore

    init(unlockedPhone: Binding<String>) {
        self._unlockedPhone = unlockedPhone

        let phone = AuthManager.shared.currentUser?.phone ?? "guest"
        let store = UserStore(phone: phone)

        // 首次登录同步用户名
        if let user = AuthManager.shared.currentUser {
            if store.username == "User name" || store.username.isEmpty {
                store.saveUsername(user.name)
            }
        }

        _userStore   = StateObject(wrappedValue: store)
        _ledgerStore = StateObject(wrappedValue: LedgerStore(userStore: store))
    }

    var body: some View {
        // 严格按 phone 判断：必须是当前账号自己解过锁才算
        let phone = userStore.phone
        let isUnlocked = (unlockedPhone == phone)
        let needsLock = AppLockManager.shared.isEnabled(for: phone) && !isUnlocked

        Group {
            if needsLock {
                AppLockGateView()
                    .environmentObject(userStore)
                    .environmentObject(appSettings)
            } else {
                MainRootView()
                    .environmentObject(userStore)
                    .environmentObject(ledgerStore)
                    .environmentObject(appSettings)
                    .onAppear {
                        ledgerStore.processRecurring()
                    }
            }
        }
    }
}

#Preview { ContentView().environmentObject(AppSettings()) }
