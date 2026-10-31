import SwiftUI

struct CreateLedgerView: View {
    @Environment(\.colorScheme) var colorScheme

    private let accent = Color(hex: "7E6AD6")
    private let plusBg = Color(hex: "DCCAF6")

    var isDark: Bool { colorScheme == .dark }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor: Color { isDark ? .white : .black }
    var subColor:  Color { isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.35) }

    @State private var ledgerName: String = ""
    @State private var showAlert: Bool = false
    @State private var selectedSymbol: String = "book.fill"
    @State private var customEmojiText: String = ""
    @State private var showCustomInput = false
    @State private var showIconPicker  = false
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var customEmojiFocused: Bool

    // SF Symbol 图标列表
    private let iconOptions: [(symbol: String, label: String)] = [
        ("book.fill",              "Ledger"),
        ("dollarsign.circle.fill", "Money"),
        ("house.fill",             "Home"),
        ("car.fill",               "Car"),
        ("airplane",               "Travel"),
        ("gamecontroller.fill",    "Game"),
        ("fork.knife",             "Food"),
        ("cross.fill",             "Health"),
        ("cart.fill",              "Shopping"),
        ("briefcase.fill",         "Work"),
        ("music.note",             "Music"),
        ("pawprint.fill",          "Pet"),
        ("figure.run",             "Fitness"),
        ("leaf.fill",              "Nature"),
        ("lightbulb.fill",         "Idea"),
        ("cup.and.saucer.fill",    "Café"),
        ("laptopcomputer",         "Tech"),
        ("star.fill",              "Goals"),
        ("gift.fill",              "Gifts"),
        ("globe",                  "World"),
        ("building.columns.fill",  "Bank"),
        ("creditcard.fill",        "Card"),
        ("heart.fill",             "Love"),
        ("flame.fill",             "Hot"),
    ]

    var onSave: (String, String) -> Void

    // 最终存储值：自定义 emoji 用 "custom:XXX"，SF Symbol 直接存 symbol 名
    private var storedEmoji: String {
        if !customEmojiText.isEmpty { return "custom:" + customEmojiText }
        return selectedSymbol
    }

    private var canSave: Bool { !ledgerName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.gray.opacity(0.35))
                        .frame(width: 40, height: 4)
                        .padding(.top, 14).padding(.bottom, 20)

                    Text(t("new_ledger_title"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textColor)
                        .padding(.bottom, 24)

                    // 预览大图标 — 点击弹出选择器
                    Button { showIconPicker = true } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(plusBg.opacity(isDark ? 0.30 : 0.55))
                                .frame(width: 100, height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(accent.opacity(0.35), lineWidth: 2))
                            if !customEmojiText.isEmpty {
                                Text(customEmojiText)
                                    .font(.system(size: 42))
                            } else {
                                Image(systemName: selectedSymbol)
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(accent)
                            }
                            Circle().fill(accent).frame(width: 26, height: 26)
                                .overlay(Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white))
                                .offset(x: 34, y: 34)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 8)

                    Text(t("tap_choose_icon"))
                        .font(.system(size: 12))
                        .foregroundColor(subColor)
                        .padding(.bottom, 20)

                    // Custom emoji input
                    HStack(spacing: 10) {
                        if showCustomInput {
                            TextField(t("enter_custom_emoji"), text: $customEmojiText)
                                .focused($customEmojiFocused)
                                .font(.system(size: 24))
                                .frame(width: 140)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(card))
                            Button {
                                showCustomInput = false
                                customEmojiText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(subColor)
                            }
                        } else {
                            Button {
                                nameFieldFocused = false
                                showCustomInput = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    customEmojiFocused = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14))
                                    Text(t("custom_emoji"))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(accent)
                            }
                        }
                    }
                    .padding(.bottom, 28)

                    // Ledger Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("ledger_name_label"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(subColor)
                            .padding(.horizontal, 4)
                        TextField(t("ledger_name_placeholder"), text: $ledgerName)
                            .focused($nameFieldFocused)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(textColor)
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(card))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(nameFieldFocused ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5))
                    }
                    .padding(.horizontal, 24).padding(.bottom, 28)

                    Button {
                        let name = ledgerName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else {
                            showAlert = true
                            return
                        }
                        nameFieldFocused = false
                        onSave(name, storedEmoji)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark").font(.system(size: 16, weight: .bold))
                            Text(t("create_ledger_btn")).font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(canSave ? accent : accent.opacity(0.35)))
                        .padding(.horizontal, 24)
                    }
                    .disabled(!canSave)

                    Spacer().frame(height: 40)
                }
            }
        }
        .onTapGesture {
            nameFieldFocused = false
            customEmojiFocused = false
        }
        // Icon picker sheet
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
        .alert(t("check_input"), isPresented: $showAlert) { Button(t("ok_btn"), role: .cancel) {} }
    }

    // MARK: - Icon Picker Sheet (half-screen, wheel style)
    private var iconPickerSheet: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4).padding(.top, 14).padding(.bottom, 16)

            Text(t("choose_icon"))
                .font(.system(size: 18, weight: .bold)).foregroundColor(textColor)
                .padding(.bottom, 12)

            // Current selection
            ZStack {
                Circle().fill(accent).frame(width: 56, height: 56)
                if !customEmojiText.isEmpty {
                    Text(customEmojiText).font(.system(size: 28))
                } else {
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
                }
            }
            .padding(.bottom, 6)
            Text(iconOptions.first { $0.symbol == selectedSymbol }?.label ?? "")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(accent)
                .padding(.bottom, 16)

            // Wheel scroll
            wheelPicker
                .frame(height: 90)
                .padding(.bottom, 20)

            // Done button
            Button { showIconPicker = false } label: {
                Text(t("done"))
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(accent))
            }
            .padding(.horizontal, 24).padding(.bottom, 30)
        }
        .background(bg.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private var wheelPicker: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        Color.clear.frame(width: geo.size.width / 2 - 32)
                        ForEach(iconOptions, id: \.symbol) { opt in
                            GeometryReader { item in
                                let midX    = geo.size.width / 2
                                let itemMid = item.frame(in: .global).midX
                                let dist    = abs(midX - itemMid)
                                let scale   = max(0.58, 1.0 - dist / 120 * 0.42)
                                let opacity = max(0.30, 1.0 - Double(dist / 120) * 0.70)
                                Button {
                                    customEmojiText = ""
                                    withAnimation(.spring(response: 0.25)) {
                                        selectedSymbol = opt.symbol
                                    }
                                } label: {
                                    VStack(spacing: 5) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedSymbol == opt.symbol ? accent : card)
                                                .frame(width: 56, height: 56)
                                            Image(systemName: opt.symbol)
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundColor(selectedSymbol == opt.symbol ? .white : (isDark ? .white.opacity(0.7) : accent.opacity(0.7)))
                                        }
                                        Text(opt.label)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(selectedSymbol == opt.symbol ? accent : subColor)
                                            .lineLimit(1)
                                    }
                                    .scaleEffect(scale)
                                    .opacity(opacity)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 64, height: 85)
                            }
                            .frame(width: 64, height: 85)
                            .id(opt.symbol)
                        }
                        Color.clear.frame(width: geo.size.width / 2 - 32)
                    }
                }
                .onAppear { proxy.scrollTo(selectedSymbol, anchor: .center) }
            }
        }
    }
}

#Preview("Create Ledger") {
    CreateLedgerView { name, emoji in print("Created: \(emoji) \(name)") }
}
