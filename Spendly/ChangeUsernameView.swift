import SwiftUI

struct ChangeUsernameView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userStore: UserStore

    private let accent = Color(hex: "7E6AD6")

    var isDark: Bool { colorScheme == .dark }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    @State private var newUsername = ""
    @FocusState private var isFocused: Bool
    @State private var saved = false

    private var canSave: Bool { !newUsername.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar(title: t("change_username"))
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("current_username"))
                            .font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                        Text(userStore.username)
                            .font(.system(size: 18, weight: .medium)).foregroundColor(textColor.opacity(0.55))
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(card))
                    }
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("new_username_label"))
                            .font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                        TextField(t("enter_new_username"), text: $newUsername)
                            .focused($isFocused)
                            .font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(card))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isFocused ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5))
                    }

                    Spacer()

                    Button {
                        guard canSave else { return }
                        isFocused = false
                        userStore.saveUsername(newUsername.trimmingCharacters(in: .whitespaces))
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                    } label: {
                        HStack(spacing: 8) {
                            if saved { Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)) }
                            Text(saved ? t("saved") : t("save_changes")).font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(canSave ? (saved ? Color.green : accent) : accent.opacity(0.35)))
                    }
                    .disabled(!canSave || saved)
                    .animation(.easeInOut(duration: 0.2), value: saved)
                    .padding(.bottom, 110)
                }
                .padding(.horizontal, 24)
            }
            BottomBarView(bg: bg, accent: accent, active: .profile, onHome: {}, onPlus: {}, onProfile: {})
        }
        .navigationBarHidden(true)
        .onTapGesture { isFocused = false }
    }

    private func topBar(title: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
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

#Preview { NavigationStack { ChangeUsernameView().environmentObject(UserStore()) } }
