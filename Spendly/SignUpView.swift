import SwiftUI

struct SignUpView: View {

    var onBackToLogin: () -> Void

    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var auth = AuthManager.shared

    private let accent = Color(hex: "7E6AD6")

    var isDark:    Bool  { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "EDE8F5") }
    var cardBg:    Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "FFFAFA") }
    var fieldBg:   Color { isDark ? Color(hex: "3A3A3C") : Color(hex: "F0ECF8") }
    var textColor: Color { isDark ? .white : Color(hex: "2C2C2E") }
    var subColor:  Color { isDark ? Color.white.opacity(0.45) : Color(hex: "9E9E9E") }

    @State private var name = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirm   = false
    @State private var errorMessage  = ""
    @State private var isLoading     = false
    @State private var registerSuccess = false

    var body: some View {
        Group {
            if registerSuccess {
                LoginSuccessView(welcomeText: "Registration Successful!", subText: "Welcome to Spendly!")
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
                        HStack {
                            Button(action: onBackToLogin) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold)).foregroundColor(accent)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24).padding(.top, 32)

                        Text("Spendly").font(customJulee(size: 48)).foregroundColor(accent)

                        ZStack {
                            Circle().fill(isDark ? Color(hex: "3A3A3C") : Color(hex: "EDE8F5"))
                                .frame(width: 90, height: 90)
                            Image(systemName: "person.crop.circle.fill")
                                .resizable().scaledToFit().frame(width: 72, height: 72)
                                .foregroundColor(accent.opacity(0.6))
                        }

                        Text(t("create_account"))
                            .font(.system(size: 22, weight: .bold)).foregroundColor(textColor)

                        VStack(spacing: 14) {
                            fieldRow(icon: "person",    placeholder: t("your_name"),              text: $name)
                            fieldRow(icon: "phone",     placeholder: t("phone_number"),            text: $phone, keyboard: .phonePad)
                            secureRow(icon: "lock",     placeholder: t("password_min_6"),  text: $password, show: $showPassword)
                            secureRow(icon: "lock.fill", placeholder: t("confirm_password"),       text: $confirmPassword, show: $showConfirm)
                        }
                        .padding(.horizontal, 24)

                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.system(size: 13)).foregroundColor(.red)
                                .padding(.horizontal, 24).multilineTextAlignment(.center)
                        }

                        Button(action: handleRegister) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30).fill(accent).frame(height: 54)
                                if isLoading { ProgressView().tint(.white) }
                                else { Text(t("sign_up")).font(.system(size: 18, weight: .semibold)).foregroundColor(.white) }
                            }
                        }
                        .padding(.horizontal, 24).disabled(isLoading)

                        HStack(spacing: 4) {
                            Text(t("have_account")).font(.system(size: 14)).foregroundColor(subColor)
                            Button(t("log_in")) { onBackToLogin() }
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

    @ViewBuilder
    private func fieldRow(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(subColor)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .foregroundColor(textColor).tint(accent)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 14).fill(fieldBg))
    }

    @ViewBuilder
    private func secureRow(icon: String, placeholder: String, text: Binding<String>, show: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(subColor)
            Group {
                if show.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .foregroundColor(textColor).tint(accent)
            Button { show.wrappedValue.toggle() } label: {
                Image(systemName: show.wrappedValue ? "eye" : "eye.slash").foregroundColor(subColor)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 14).fill(fieldBg))
    }

    private func handleRegister() {
        errorMessage = ""
        guard password == confirmPassword else { errorMessage = "Passwords do not match"; return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if let error = auth.register(phone: phone, password: password, name: name) {
                errorMessage = error; isLoading = false
            } else {
                _ = auth.login(phone: phone, password: password)
                isLoading = false
                withAnimation { registerSuccess = true }
            }
        }
    }

    private func customJulee(size: CGFloat) -> Font {
        UIFont(name: "Julee", size: size) != nil ? .custom("Julee", size: size) : .system(size: size, weight: .regular, design: .rounded)
    }
}

// =============================================
// LoginSuccessView
// =============================================

struct LoginSuccessView: View {
    var welcomeText: String = "Login Successful!"
    var subText: String = "Welcome back!"

    @EnvironmentObject var appSettings: AppSettings

    private let accent   = Color(hex: "7E6AD6")

    var isDark: Bool { appSettings.isDarkMode }
    var bgTop:    Color { isDark ? Color(hex: "2C2055") : Color(hex: "D8D0F0") }
    var bgBottom: Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "EDE8F5") }

    @State private var checkScale: CGFloat = 0
    @State private var showText = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ForEach(0..<6) { i in
                Circle().fill(Color.white.opacity(isDark ? 0.06 : 0.25))
                    .frame(width: CGFloat([120,80,100,60,90,70][i]), height: CGFloat([120,80,100,60,90,70][i]))
                    .offset(x: CGFloat([-140,100,-80,130,-110,90][i]), y: CGFloat([-300,-250,-180,-100,200,280][i]))
                    .blur(radius: 8)
            }
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(Color.white.opacity(isDark ? 0.10 : 0.40)).frame(width: 140, height: 140)
                    Image(systemName: "person.crop.circle.fill")
                        .resizable().scaledToFit().frame(width: 110, height: 110)
                        .foregroundColor(accent.opacity(0.7))
                    ZStack {
                        Circle().fill(accent).frame(width: 42, height: 42)
                        Image(systemName: "checkmark").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    }
                    .scaleEffect(checkScale).offset(x: 40, y: 40)
                }
                VStack(spacing: 8) {
                    Text(welcomeText).font(.system(size: 26, weight: .bold))
                        .foregroundColor(isDark ? .white : .primary.opacity(0.85))
                    Text(subText).font(.system(size: 16))
                        .foregroundColor(isDark ? Color.white.opacity(0.55) : .primary.opacity(0.5))
                }
                .opacity(showText ? 1 : 0)
                Button(action: {
                    // auth.isLoggedIn 已经是 true，ContentView 持有 @StateObject auth
                    // 会自动检测到变化并切换到 MainRootView，无需额外操作
                }) {
                    Text(t("get_started")).font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                        .frame(width: 220, height: 52)
                        .background(RoundedRectangle(cornerRadius: 30).fill(accent.opacity(0.85)))
                }
                .opacity(showText ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { checkScale = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) { showText = true }
            // 自动跳转：auth.isLoggedIn 已为 true，ContentView (@StateObject) 会响应
        }
    }
}

#Preview { SignUpView(onBackToLogin: {}).environmentObject(AppSettings()) }
#Preview("Success") { LoginSuccessView().environmentObject(AppSettings()) }
