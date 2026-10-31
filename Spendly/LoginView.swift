import SwiftUI

// ================================================
// LoginView — 老师负责实现
// 这个文件是占位，不要修改
// ================================================

struct LoginView: View {
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var auth = AuthManager.shared

    private let accent = Color(hex: "7E6AD6")

    var isDark:    Bool  { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "EDE8F5") }
    var cardBg:    Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "FFFAFA") }
    var fieldBg:   Color { isDark ? Color(hex: "3A3A3C") : Color(hex: "F0ECF8") }
    var textColor: Color { isDark ? .white : Color(hex: "2C2C2E") }
    var subColor:  Color { isDark ? Color.white.opacity(0.45) : Color(hex: "9E9E9E") }

    @State private var showSignUp   = false
    @State private var phone        = ""
    @State private var password     = ""
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var isLoading    = false
    @State private var loginSuccess = false

    var body: some View {
        Group {
            if loginSuccess {
                LoginSuccessView()
                    .environmentObject(appSettings)
            } else if showSignUp {
                SignUpView(onBackToLogin: { showSignUp = false })
                    .environmentObject(appSettings)
            } else {
                mainBody
            }
        }
        .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
    }

    private var mainBody: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        Text("Spendly")
                            .font(customJulee(size: 54))
                            .foregroundColor(accent)
                            .padding(.top, 52)

                        ZStack {
                            Circle()
                                .fill(isDark ? Color(hex: "3A3A3C") : Color(hex: "EDE8F5"))
                                .frame(width: 90, height: 90)
                            Image(systemName: "creditcard.fill")
                                .resizable().scaledToFit()
                                .frame(width: 48, height: 48)
                                .foregroundColor(accent.opacity(0.7))
                        }

                        Text(t("welcome_back"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(textColor)

                        VStack(spacing: 14) {
                            // Phone
                            HStack(spacing: 12) {
                                Image(systemName: "phone").foregroundColor(subColor)
                                TextField(t("phone_number"), text: $phone)
                                    .keyboardType(.phonePad)
                                    .foregroundColor(textColor).tint(accent)
                            }
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(fieldBg))

                            // Password
                            HStack(spacing: 12) {
                                Image(systemName: "lock").foregroundColor(subColor)
                                Group {
                                    if showPassword {
                                        TextField(t("password_label"), text: $password)
                                    } else {
                                        SecureField(t("password_label"), text: $password)
                                    }
                                }
                                .foregroundColor(textColor).tint(accent)
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye" : "eye.slash")
                                        .foregroundColor(subColor)
                                }
                            }
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(fieldBg))
                        }
                        .padding(.horizontal, 24)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13)).foregroundColor(.red)
                                .padding(.horizontal, 24)
                        }

                        // Login button
                        Button(action: handleLogin) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30).fill(accent).frame(height: 54)
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(t("sign_in"))
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .disabled(isLoading)

                        HStack(spacing: 4) {
                            Text(t("no_account"))
                                .font(.system(size: 14)).foregroundColor(subColor)
                            Button(t("sign_up")) { showSignUp = true }
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                        }
                        .padding(.vertical, 28)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(cardBg)
                            .shadow(color: .black.opacity(isDark ? 0.4 : 0.06), radius: 20, x: 0, y: 4)
                    )
                    .padding(.horizontal, 18).padding(.top, 32).padding(.bottom, 40)
                }
            }
        }
    }

    private func handleLogin() {
        errorMessage = ""
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let error = auth.login(phone: phone, password: password) {
                errorMessage = error
                isLoading = false
            } else {
                isLoading = false
                withAnimation { loginSuccess = true }
            }
        }
    }

    private func customJulee(size: CGFloat) -> Font {
        UIFont(name: "Julee", size: size) != nil
            ? .custom("Julee", size: size)
            : .system(size: size, weight: .regular, design: .rounded)
    }
}

#Preview {
    LoginView().environmentObject(AppSettings())
}
