import SwiftUI

// ================================================
// AppLockSetupView
// 流程：验证账户密码 → 输入新 PIN → 确认 PIN
// ================================================

struct AppLockSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userStore: UserStore

    var isChanging: Bool = false   // true = 修改已有 pin
    var onDone: (() -> Void)? = nil

    private let accent = Color(hex: "7E6AD6")
    var isDark: Bool { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var cardBg:    Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    // Steps
    enum Step { case verifyAccount, setPin, confirmPin }
    @State private var step: Step = .verifyAccount

    // Verify account
    @State private var accountPassword = ""
    @State private var accountError    = ""

    // Set PIN
    @State private var newPin      = ""
    @State private var confirmPin  = ""
    @State private var pinError    = ""
    @State private var pinShake    = false

    // Navigate to reset password
    @State private var showResetPassword = false

    var phone: String { userStore.phone }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                    switch step {
                    case .verifyAccount: verifyAccountView
                    case .setPin:        pinEntryView(title: isChanging ? t("new_app_lock_pin") : t("set_app_lock_pin"),
                                                      subtitle: t("pin_hint"),
                                                      pin: $newPin, error: $pinError,
                                                      onComplete: { step = .confirmPin })
                    case .confirmPin:    pinEntryView(title: t("confirm_pin"),
                                                      subtitle: t("confirm_pin_hint"),
                                                      pin: $confirmPin, error: $pinError,
                                                      onComplete: { finishSetup() })
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(isDark ? .dark : .light)
            .navigationDestination(isPresented: $showResetPassword) {
                ResetPasswordView().environmentObject(userStore).environmentObject(appSettings)
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(textColor)
                }
                Spacer()
                Text(isChanging ? t("change_app_lock") : t("set_app_lock"))
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(textColor)
                Spacer()
                // 平衡左右
                Image(systemName: "xmark").opacity(0)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }.background(bg)
    }

    // MARK: - Step 1: Verify account password
    private var verifyAccountView: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 24)

                // 图标
                ZStack {
                    Circle().fill(accent.opacity(0.12)).frame(width: 72, height: 72)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32)).foregroundColor(accent)
                }

                VStack(spacing: 6) {
                    Text(t("verify_account_title"))
                        .font(.system(size: 22, weight: .bold)).foregroundColor(textColor)
                    Text(t("verify_account_sub"))
                        .font(.system(size: 14)).foregroundColor(subColor)
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }

                // 密码输入框
                VStack(alignment: .leading, spacing: 8) {
                    SecureField(t("password"), text: $accountPassword)
                        .font(.system(size: 16))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
                        .autocorrectionDisabled()
                    if !accountError.isEmpty {
                        Text(accountError)
                            .font(.system(size: 13)).foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 24)

                // 继续按钮
                Button { verifyAccountPassword() } label: {
                    Text(t("continue"))
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Capsule().fill(accountPassword.isEmpty ? accent.opacity(0.4) : accent))
                }
                .disabled(accountPassword.isEmpty)
                .padding(.horizontal, 24)

                // 忘记密码
                Button {
                    showResetPassword = true
                } label: {
                    Text(t("forgot_password"))
                        .font(.system(size: 14)).foregroundColor(accent)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2 & 3: PIN entry (numpad)
    private func pinEntryView(title: String, subtitle: String, pin: Binding<String>, error: Binding<String>, onComplete: @escaping () -> Void) -> some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Text(title).font(.system(size: 22, weight: .bold)).foregroundColor(textColor)
                Text(subtitle).font(.system(size: 14)).foregroundColor(subColor)
            }

            // 4 个圆点
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < pin.wrappedValue.count ? accent : cardBg)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(accent.opacity(0.4), lineWidth: 1.5))
                }
            }
            .modifier(ShakeModifier(shake: pinShake))

            if !error.wrappedValue.isEmpty {
                Text(error.wrappedValue)
                    .font(.system(size: 13)).foregroundColor(.red)
            }

            // 数字键盘
            numpad(pin: pin, onComplete: onComplete)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Numpad
    private func numpad(pin: Binding<String>, onComplete: @escaping () -> Void) -> some View {
        let keys: [[String]] = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","⌫"]]
        return VStack(spacing: 16) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 32) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Circle().fill(Color.clear).frame(width: 72, height: 72)
                        } else {
                            Button {
                                handleKey(key, pin: pin, onComplete: onComplete)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(isDark ? Color(hex: "2C2C2E") : Color(hex: "F0EEF8"))
                                        .frame(width: 72, height: 72)
                                    Text(key)
                                        .font(.system(size: key == "⌫" ? 22 : 26, weight: .medium))
                                        .foregroundColor(textColor)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Logic
    private func handleKey(_ key: String, pin: Binding<String>, onComplete: @escaping () -> Void) {
        pinError = ""
        if key == "⌫" {
            if !pin.wrappedValue.isEmpty { pin.wrappedValue.removeLast() }
        } else if pin.wrappedValue.count < 4 {
            pin.wrappedValue.append(key)
            if pin.wrappedValue.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { onComplete() }
            }
        }
    }

    private func verifyAccountPassword() {
        let auth = AuthManager.shared
        if auth.verifyPassword(accountPassword, for: phone) {
            accountError = ""
            withAnimation { step = .setPin }
        } else {
            accountError = t("incorrect_password")
        }
    }

    private func finishSetup() {
        guard newPin.count == 4, confirmPin.count == 4 else { return }
        if newPin != confirmPin {
            pinError = t("pin_mismatch")
            confirmPin = ""
            withAnimation(.default) { pinShake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pinShake = false }
        } else {
            AppLockManager.shared.savePin(newPin, for: phone)
            AppLockManager.shared.unlock()  // 设置完直接解锁当前会话
            onDone?()
            dismiss()
        }
    }
}

// MARK: - Shake modifier
struct ShakeModifier: ViewModifier {
    var shake: Bool
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? -10 : 0)
            .animation(shake ? Animation.linear(duration: 0.05).repeatCount(5, autoreverses: true) : .default, value: shake)
    }
}
