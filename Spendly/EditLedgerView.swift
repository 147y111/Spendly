import SwiftUI

struct EditLedgerView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lm = LocalizationManager.shared
    @Environment(\.dismiss) var dismiss

    private let accent = Color(hex: "7E6AD6")
    private let plusBg = Color(hex: "DCCAF6")

    var isDark: Bool { colorScheme == .dark }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor: Color { isDark ? .white : .black }
    var subColor:  Color { isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.35) }

    let ledger: Ledger
    var onSave: (String, String) -> Void

    @State private var ledgerName: String
    @State private var showAlert: Bool = false
    @State private var selectedSymbol: String
    @State private var customEmojiText: String
    @State private var showIconPicker = false
    @State private var showCustomInput = false
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var customEmojiFocused: Bool

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

    init(ledger: Ledger, onSave: @escaping (String, String) -> Void) {
        self.ledger = ledger
        self.onSave = onSave
        _ledgerName = State(initialValue: ledger.name)
        // 判断存储的是 custom: 前缀的 emoji 还是 SF Symbol
        if ledger.emoji.hasPrefix("custom:") {
            _selectedSymbol  = State(initialValue: "book.fill")
            _customEmojiText = State(initialValue: String(ledger.emoji.dropFirst(7)))
        } else {
            _selectedSymbol  = State(initialValue: ledger.emoji.isEmpty ? "book.fill" : ledger.emoji)
            _customEmojiText = State(initialValue: "")
        }
    }

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

                    Text(t("edit_ledger"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textColor)
                        .padding(.bottom, 24)

                    // Icon preview — tap to open picker
                    Button { showIconPicker = true } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(plusBg.opacity(isDark ? 0.30 : 0.55))
                                .frame(width: 100, height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(accent.opacity(0.35), lineWidth: 2))
                            if !customEmojiText.isEmpty {
                                Text(customEmojiText).font(.system(size: 42))
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
                        .font(.system(size: 12)).foregroundColor(subColor)
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
                                    .font(.system(size: 20)).foregroundColor(subColor)
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
                                    Image(systemName: "plus.circle").font(.system(size: 14))
                                    Text(t("custom_emoji")).font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(accent)
                            }
                        }
                    }
                    .padding(.bottom, 28)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("ledger_name_label"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(subColor).padding(.horizontal, 4)
                        TextField(t("ledger_name_placeholder"), text: $ledgerName)
                            .focused($nameFieldFocused)
                            .font(.system(size: 18, weight: .medium)).foregroundColor(textColor)
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(card))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(nameFieldFocused ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5))
                    }
                    .padding(.horizontal, 24).padding(.bottom, 28)

                    Button {
                        guard canSave else {
                        showAlert = true
                        return
                    }
                        nameFieldFocused = false
                        onSave(ledgerName.trimmingCharacters(in: .whitespaces), storedEmoji)
                    } label: {
                        Text(t("save"))
                            .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Capsule().fill(canSave ? accent : accent.opacity(0.35)))
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .onTapGesture { nameFieldFocused = false; customEmojiFocused = false }
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
        .alert(t("check_input"), isPresented: $showAlert) { Button(t("ok_btn"), role: .cancel) {} }
    }

    // MARK: - Icon Picker Sheet
    private var iconPickerSheet: some View {
        IconPickerSheetContent(
            selectedSymbol: $selectedSymbol,
            customEmojiText: $customEmojiText,
            iconOptions: iconOptions,
            accent: accent,
            onDone: { showIconPicker = false }
        )
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
                                    .scaleEffect(scale).opacity(opacity)
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


// 独立 struct 避免 sheet 里 computed property 断链
struct IconPickerSheetContent: View {
    @Binding var selectedSymbol: String
    @Binding var customEmojiText: String
    let iconOptions: [(symbol: String, label: String)]
    let accent: Color
    let onDone: () -> Void

    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool { colorScheme == .dark }
    var textClr: Color { isDark ? .white : .black.opacity(0.85) }
    var subClr:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.45) }
    var cardClr: Color { isDark ? Color(hex: "3A3A3C") : Color(hex: "F0EEF8") }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4).padding(.top, 14).padding(.bottom, 16)
            Text(t("choose_icon"))
                .font(.system(size: 18, weight: .bold)).foregroundColor(textClr).padding(.bottom, 12)
            ZStack {
                Circle().fill(accent).frame(width: 56, height: 56)
                if !customEmojiText.isEmpty {
                    Text(customEmojiText).font(.system(size: 28))
                } else {
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
                }
            }
            .padding(.bottom, 4)
            Text(iconOptions.first { $0.symbol == selectedSymbol }?.label ?? "")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(accent).padding(.bottom, 16)
            // Wheel picker
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
                                        withAnimation(.spring(response: 0.25)) { selectedSymbol = opt.symbol }
                                    } label: {
                                        VStack(spacing: 5) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedSymbol == opt.symbol ? accent : cardClr)
                                                    .frame(width: 56, height: 56)
                                                Image(systemName: opt.symbol)
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundColor(selectedSymbol == opt.symbol ? .white : accent.opacity(0.7))
                                            }
                                            Text(opt.label)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(selectedSymbol == opt.symbol ? accent : subClr)
                                                .lineLimit(1)
                                        }
                                        .scaleEffect(scale).opacity(opacity)
                                    }
                                    .buttonStyle(.plain).frame(width: 64, height: 85)
                                }
                                .frame(width: 64, height: 85).id(opt.symbol)
                            }
                            Color.clear.frame(width: geo.size.width / 2 - 32)
                        }
                    }
                    .onAppear { proxy.scrollTo(selectedSymbol, anchor: .center) }
                }
            }
            .frame(height: 90).padding(.bottom, 20)
            Button { onDone() } label: {
                Text(t("done"))
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(accent))
            }
            .padding(.horizontal, 24).padding(.bottom, 30)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}
