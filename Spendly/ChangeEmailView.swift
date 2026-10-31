import SwiftUI

struct ChangeEmailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")

    var isDark: Bool { colorScheme == .dark }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    enum Step { case verifyPassword, enterEmail }
    @State private var step: Step = .verifyPassword
    @State private var password   = ""
    @State private var newEmail   = ""
    @State private var showError  = false
    @State private var errorMsg   = ""
    @State private var saved      = false
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    enum Field { case password, email }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar(title: t("change_email"))
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        stepDot(index: 1, label: t("verify"), active: step == .verifyPassword, done: step == .enterEmail)
                        Rectangle()
                            .fill(step == .enterEmail ? accent : (isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.15)))
                            .frame(height: 2).frame(maxWidth: .infinity)
                            .animation(.easeInOut, value: step)
                        stepDot(index: 2, label: t("new_email_address"), active: step == .enterEmail, done: false)
                    }
                    .padding(.horizontal, 40).padding(.top, 28).padding(.bottom, 32)

                    if step == .verifyPassword {
                        passwordStep.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    } else {
                        emailStep.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                    Spacer()
                }
            }
            BottomBarView(bg: bg, accent: accent, active: .profile, onHome: {}, onPlus: {}, onProfile: {})
        }
        .navigationBarHidden(true)
        .onTapGesture { focusedField = nil }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private var passwordStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t("enter_current_password"))
                    .font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                HStack {
                    Group {
                        if showPassword { TextField(t("password_label"), text: $password) }
                        else { SecureField(t("password_label"), text: $password) }
                    }
                    .focused($focusedField, equals: .password)
                    .font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye").foregroundColor(subColor)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(card))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(showError ? Color.red.opacity(0.5) : (focusedField == .password ? accent.opacity(0.5) : Color.clear), lineWidth: 1.5))
                if showError { Text(errorMsg).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 4) }
            }
            .padding(.horizontal, 24)
            Button { verifyPassword() } label: {
                Text(t("continue")).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(!password.isEmpty ? accent : accent.opacity(0.35)))
            }
            .disabled(password.isEmpty).padding(.horizontal, 24)
        }
    }

    private var emailStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t("current_email")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                Text(userStore.email.isEmpty ? "—" : userStore.email)
                    .font(.system(size: 18, weight: .medium)).foregroundColor(textColor.opacity(0.55))
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(card))
            }
            .padding(.horizontal, 24)
            VStack(alignment: .leading, spacing: 8) {
                Text(t("new_email_address")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                TextField(t("enter_new_email"), text: $newEmail)
                    .focused($focusedField, equals: .email)
                    .keyboardType(.emailAddress).autocapitalization(.none)
                    .font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(card))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(focusedField == .email ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5))
            }
            .padding(.horizontal, 24)
            Button {
                guard isValidEmail(newEmail) else { showError = true; errorMsg = "Please enter a valid email address."; return }
                userStore.saveEmail(newEmail.trimmingCharacters(in: .whitespacesAndNewlines))
                saved = true; focusedField = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
            } label: {
                HStack(spacing: 8) {
                    if saved { Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)) }
                    Text(saved ? "Saved!" : "Save Email").font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(!newEmail.isEmpty ? (saved ? Color.green : accent) : accent.opacity(0.35)))
            }
            .disabled(newEmail.isEmpty || saved)
            .animation(.easeInOut(duration: 0.2), value: saved)
            .padding(.horizontal, 24)
        }
    }

    private func stepDot(index: Int, label: String, active: Bool, done: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(active || done ? accent : (isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.12))).frame(width: 28, height: 28)
                if done { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white) }
                else { Text("\(index)").font(.system(size: 13, weight: .bold)).foregroundColor(active ? .white : subColor) }
            }
            Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(active || done ? accent : subColor)
        }
    }

    private func verifyPassword() {
        focusedField = nil
        if AuthManager.shared.verifyPassword(password, for: userStore.phone) {
            showError = false; withAnimation { step = .enterEmail }
        } else {
            showError = true; errorMsg = "Incorrect password. Please try again."
        }
    }
    private func isValidEmail(_ email: String) -> Bool { email.contains("@") && email.contains(".") }

    private func topBar(title: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button {
                    if step == .enterEmail { withAnimation { step = .verifyPassword } } else { dismiss() }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(textColor)
                }
                Text(title).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }
        .background(bg.ignoresSafeArea(edges: .top))
    }
}

#Preview { NavigationStack { ChangeEmailView().environmentObject(UserStore()) } }
