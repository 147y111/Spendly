//
//  ResetPasswordView.swift
//  Spendly copy
//
//  Created by Qi on 3/14/26.
//


import SwiftUI
import Combine

struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")

    var isDark: Bool { colorScheme == .dark }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var cardBg:    Color { isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.85) }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    enum Step   { case chooseMethod, verify, newPassword }

    @State private var step:   Step   = .chooseMethod
    @State private var oldPassword  = ""
    @State private var newPassword  = ""
    @State private var confirmPass  = ""
    @State private var showOld      = false
    @State private var showNew      = false
    @State private var showConfirm  = false
    @State private var showError    = false
    @State private var errorMsg     = ""
    @State private var saved        = false
    @FocusState private var focused: Field?
    enum Field { case oldPw, newPw, confirmPw }

    private var canProceedVerify: Bool { !oldPassword.isEmpty }
    private var canSave: Bool { newPassword.count >= 6 && newPassword == confirmPass }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                stepIndicator.padding(.top, 24).padding(.bottom, 28)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        switch step {
                        case .chooseMethod: chooseMethodStep
                        case .verify:       verifyStep
                        case .newPassword:  newPasswordStep
                        }
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.3), value: step)
                }
            }
            BottomBarView(bg: bg, accent: accent, active: .profile, onHome: {}, onPlus: {}, onProfile: {})
        }
        .navigationBarHidden(true)
        .onTapGesture { focused = nil }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button {
                    if step == .newPassword { withAnimation { step = .verify } }
                    else if step == .verify { withAnimation { step = .chooseMethod } }
                    else { dismiss() }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(textColor)
                }
                Text(t("reset_password")).font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Divider().opacity(0.15)
        }
        .background(bg.ignoresSafeArea(edges: .top))
    }

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            stepDot(index: 1, label: t("method"),       active: step == .chooseMethod, done: step == .verify || step == .newPassword)
            stepLine(filled: step == .verify || step == .newPassword)
            stepDot(index: 2, label: t("verify"),       active: step == .verify,       done: step == .newPassword)
            stepLine(filled: step == .newPassword)
            stepDot(index: 3, label: t("new_password"), active: step == .newPassword,  done: false)
        }
        .padding(.horizontal, 28)
    }

    private func stepLine(filled: Bool) -> some View {
        Rectangle()
            .fill(filled ? accent : (isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.15)))
            .frame(height: 2).frame(maxWidth: .infinity).animation(.easeInOut, value: filled)
    }

    private func stepDot(index: Int, label: String, active: Bool, done: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(active || done ? accent : (isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.12))).frame(width: 28, height: 28)
                if done { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white) }
                else { Text("\(index)").font(.system(size: 13, weight: .bold)).foregroundColor(active ? .white : subColor) }
            }
            Text(label).font(.system(size: 10, weight: .medium))
                .foregroundColor(active || done ? accent : subColor)
                .multilineTextAlignment(.center).frame(width: 64)
        }
    }

    private var chooseMethodStep: some View {
        VStack(spacing: 14) {
            Text(t("reset_how"))
                .font(.system(size: 15, weight: .medium)).foregroundColor(subColor)
                .multilineTextAlignment(.center).padding(.bottom, 8)
            methodCard(icon: "lock.rotation", title: t("use_old_password"), subtitle: t("use_old_password_desc"), selected: true) {}
            Button {
                showError = false; withAnimation { step = .verify }
            } label: {
                Text(t("continue")).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(accent))
            }
            .padding(.top, 8)
        }
    }

    private func methodCard(icon: String, title: String, subtitle: String, selected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(selected ? accent.opacity(0.12) : card).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 20)).foregroundColor(selected ? accent : textColor.opacity(0.55))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(textColor)
                    Text(subtitle).font(.system(size: 13)).foregroundColor(subColor).lineLimit(1)
                }
                Spacer()
                ZStack {
                    Circle().stroke(selected ? accent : subColor, lineWidth: 2).frame(width: 22, height: 22)
                    if selected { Circle().fill(accent).frame(width: 12, height: 12) }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? accent.opacity(0.4) : Color.clear, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain).animation(.easeInOut(duration: 0.15), value: selected)
    }

    private var verifyStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t("current_password")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                HStack {
                    Group {
                        if showOld { TextField(t("password_label"), text: $oldPassword) }
                        else { SecureField(t("password_label"), text: $oldPassword) }
                    }
                    .focused($focused, equals: .oldPw).font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                    Button { showOld.toggle() } label: {
                        Image(systemName: showOld ? "eye.slash" : "eye").foregroundColor(subColor)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(card))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(showError ? Color.red.opacity(0.5) : (focused == .oldPw ? accent.opacity(0.5) : Color.clear), lineWidth: 1.5))
                if showError { Text(errorMsg).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 4) }
            }
            Button { verifyAndProceed() } label: {
                Text(t("continue")).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(canProceedVerify ? accent : accent.opacity(0.35)))
            }
            .disabled(!canProceedVerify)
        }
    }

    private var newPasswordStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t("new_password")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                HStack {
                    Group {
                        if showNew { TextField(t("at_least_6"), text: $newPassword) }
                        else { SecureField(t("at_least_6"), text: $newPassword) }
                    }
                    .focused($focused, equals: .newPw).font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                    Button { showNew.toggle() } label: { Image(systemName: showNew ? "eye.slash" : "eye").foregroundColor(subColor) }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(card))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(focused == .newPw ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(t("confirm_new_password")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                HStack {
                    Group {
                        if showConfirm { TextField(t("re_enter_password"), text: $confirmPass) }
                        else { SecureField(t("re_enter_password"), text: $confirmPass) }
                    }
                    .focused($focused, equals: .confirmPw).font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                    Button { showConfirm.toggle() } label: { Image(systemName: showConfirm ? "eye.slash" : "eye").foregroundColor(subColor) }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(card))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(!confirmPass.isEmpty && confirmPass != newPassword ? Color.red.opacity(0.5) : (focused == .confirmPw ? accent.opacity(0.5) : Color.clear), lineWidth: 1.5))
                if !confirmPass.isEmpty && confirmPass != newPassword {
                    Text(t("passwords_no_match")).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 4)
                }
            }
            if !newPassword.isEmpty { strengthBar(password: newPassword) }
            Button {
                guard canSave else { return }
                focused = nil
                // 真正写入 AuthManager
                AuthManager.shared.updatePassword(newPassword, for: userStore.phone)
                saved = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
            } label: {
                HStack(spacing: 8) {
                    if saved { Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)) }
                    Text(saved ? "Password Updated!" : "Save New Password").font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(canSave ? (saved ? Color.green : accent) : accent.opacity(0.35)))
            }
            .disabled(!canSave || saved).animation(.easeInOut(duration: 0.2), value: saved)
        }
    }

    private func strengthBar(password: String) -> some View {
        let strength = passwordStrength(password)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i < strength.level ? strength.color : (isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.10)))
                        .frame(height: 4).frame(maxWidth: .infinity)
                }
            }
            Text(strength.label).font(.system(size: 12, weight: .medium)).foregroundColor(strength.color)
        }
        .animation(.easeInOut(duration: 0.2), value: password)
    }

    private struct PasswordStrength { let level: Int; let label: String; let color: Color }
    private func passwordStrength(_ pw: String) -> PasswordStrength {
        var score = 0
        if pw.count >= 8 { score += 1 }
        if pw.count >= 12 { score += 1 }
        if pw.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if pw.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if pw.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        switch score {
        case 0...1: return .init(level: 1, label: t("pwd_strength_weak"),   color: .red)
        case 2:     return .init(level: 2, label: t("pwd_strength_fair"),   color: .orange)
        case 3:     return .init(level: 3, label: t("pwd_strength_good"),   color: Color(hex: "7E6AD6"))
        default:    return .init(level: 4, label: t("pwd_strength_strong"), color: .green)
        }
    }

    private func verifyAndProceed() {
        focused = nil
        if AuthManager.shared.verifyPassword(oldPassword, for: userStore.phone) {
            showError = false; withAnimation { step = .newPassword }
        } else {
            showError = true; errorMsg = "Incorrect password. Please try again."
        }
    }
}

#Preview { NavigationStack { ResetPasswordView().environmentObject(UserStore()) } }
