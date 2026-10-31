import SwiftUI
import VisionKit

// ================================================
// DataScannerView
// ================================================

private struct DataScannerView: UIViewControllerRepresentable {
    var onResult: (String) -> Void
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.text(), .barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult, onDismiss: onDismiss) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onResult: (String) -> Void
        var onDismiss: () -> Void
        init(onResult: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
            self.onResult = onResult; self.onDismiss = onDismiss
        }
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):  onResult(text.transcript)
            case .barcode(let bc): onResult(bc.payloadStringValue ?? "")
            @unknown default: break
            }
            dataScanner.stopScanning()
            onDismiss()
        }
    }
}

// ================================================
// AddEntryView
// ================================================

struct AddEntryView: View {

    private let accent = Color(hex: "7E6AD6")

    var onSaveComplete: (() -> Void)? = nil   // 保存后回调（跳转 Home）

    @EnvironmentObject var ledgerStore: LedgerStore
    @EnvironmentObject var appSettings: AppSettings

    private var isDark:    Bool  { appSettings.isDarkMode }
    private var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    private var lightCard: Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    private var textColor: Color { isDark ? .white : .black }
    private var subColor:  Color { isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.65) }

    // MARK: - State
    enum Mode { case spend, earning }
    @State private var mode: Mode = .spend

    @State private var eventText          = ""
    @State private var noteText           = ""
    @State private var amountText         = ""
    @State private var selectedIcon:      IconType           = .meal
    @State private var hasSelectedIcon: Bool = false
    @State private var customIconEmoji: String = ""
    @State private var selectedPayMethod: PayMethod          = .cash
    @State private var selectedRecurring: RecurringFrequency = .none

    enum Field: Hashable { case event, note, amount }
    @FocusState private var focusedField: Field?

    enum AmountSize: String { case major = "Major", moderate = "Moderate", minor = "Minor" }
    @State private var amountSize: AmountSize = .minor

    @State private var isKeyboardVisible    = false
    @State private var showLedgerSwitcher   = false
    @State private var showCreateLedger     = false
    @State private var showCalendar         = false
    @State private var showScanner          = false
    @State private var showAlert: Bool = false
    @State private var showIconPicker       = false
    @State private var showPayPicker        = false
    @State private var showRecurringPicker  = false
    @State private var customDays: String = "1"
    @State private var customUnit: String = "days"
    @State private var selectedDate         = Date()

    // MARK: - Computed
    private var isFormComplete: Bool {
        !eventText.trimmingCharacters(in: .whitespaces).isEmpty && isValidAmount(amountText)
    }
    private var showSave: Bool {
        isFormComplete && !isKeyboardVisible && focusedField == nil
    }
    private var cardBackground: Color {
        switch amountSize {
        case .major:    return Color(hex: "FFE4E6").opacity(0.80)
        case .moderate: return Color(hex: "FFE1C2").opacity(0.80)
        case .minor:    return isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.95)
        }
    }
    // 大额/中额背景是亮色，深浅模式都用深色文字；小额跟随系统
    private var cardTextColor: Color {
        switch amountSize {
        case .major, .moderate: return Color(hex: "1A1A2E")
        case .minor:            return textColor
        }
    }
    private var ledger: Ledger { ledgerStore.current }
    private var dateText: String {
        let df = DateFormatter(); df.dateFormat = "MM/dd/yyyy"; return df.string(from: selectedDate)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar.padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 10)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerArea
                        modePills.padding(.horizontal, 18)
                        inputCard.padding(.horizontal, 18)
                        sizeLabels.padding(.horizontal, 18)
                        iconRow.padding(.horizontal, 18)
                        payMethodRow.padding(.horizontal, 18)
                        recurringRow.padding(.horizontal, 18)

                        // Done / Discard row
                        HStack(spacing: 12) {
                            Button {
                                // 放弃 — 清空表单
                                eventText         = ""
                                noteText          = ""
                                amountText        = ""
                                amountSize        = .minor
                                selectedIcon      = .meal
                                selectedPayMethod = .cash
                                selectedRecurring = .none
                                selectedDate      = Date()
                                focusedField      = nil
                            } label: {
                                Text(t("cancel"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(subColor)
                                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(lightCard))
                            }
                            .buttonStyle(.plain)

                            Button {
                                focusedField = nil
                                if eventText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    showAlert = true
                                } else if !isValidAmount(amountText) {
                                    showAlert = true
                                } else {
                                    saveEntry()
                                }
                            } label: {
                                let canSave = isFormComplete
                                Text(t("done"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(canSave ? .white : accent)
                                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                                    .background(RoundedRectangle(cornerRadius: 14)
                                        .fill(canSave ? accent : accent.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 18)

                        Spacer().frame(height: 160)
                    }
                    .padding(.top, 6)
                }
            }



            // Overlays
            overlayLayer(show: $showLedgerSwitcher) {
                LedgerSwitcherSheet(
                    onDismiss: { withAnimation(.spring()) { showLedgerSwitcher = false } },
                    onCreateNew: { showCreateLedger = true }
                )
                .environmentObject(ledgerStore)
            }
            // calendar via sheet below
            // icon via sheet
            // pay via sheet
            // recurring via sheet
        }
        .onTapGesture { focusedField = nil }
        .alert(t("check_input"), isPresented: $showAlert) { Button(t("ok_btn"), role: .cancel) {} }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        // keyboard toolbar removed
        .sheet(isPresented: $showScanner) { scannerSheet }
        .sheet(isPresented: $showCalendar) {
            CalendarPickerSheet(
                selectedMonth: $selectedDate,
                daysWithEntries: ledgerStore.entries.map { $0.date },
                onDismiss: { showCalendar = false }
            )
        }
        .sheet(isPresented: $showPayPicker) {
            PayMethodPickerSheet(selected: $selectedPayMethod, onDismiss: { showPayPicker = false })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRecurringPicker) {
            RecurringPickerSheet(selected: $selectedRecurring, customDays: $customDays, customUnit: $customUnit, onDismiss: { showRecurringPicker = false })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
        .sheet(isPresented: $showCreateLedger) {
            CreateLedgerView { name, emoji in
                ledgerStore.addLedger(name: name, emoji: emoji)
                showCreateLedger = false
            }
        }
    }

    // MARK: - Generic overlay helper
    @ViewBuilder
    private func overlayLayer<Content: View>(show: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        if show.wrappedValue {
            Color.black.opacity(0.30).ignoresSafeArea()
                .onTapGesture { withAnimation(.spring()) { show.wrappedValue = false } }
            VStack {
                Spacer()
                content()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 8).padding(.bottom, 100)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button { withAnimation(.spring()) { showLedgerSwitcher = true } } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 20, weight: .semibold)).foregroundColor(accent)
            }
            Spacer()
        }
    }

    // MARK: - Header
    private var headerArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 10) {
                    if ledger.isTotal {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(textColor.opacity(0.85))
                            .frame(width: 34, height: 34)
                    } else if ledger.emoji.hasPrefix("custom:") {
                        Text(String(ledger.emoji.dropFirst(7)))
                            .font(.system(size: 28))
                            .frame(width: 34, height: 34)
                    } else {
                        Image(systemName: ledger.emoji.isEmpty ? "book.fill" : ledger.emoji)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(accent)
                            .frame(width: 34, height: 34)
                    }
                    Text(ledger.name)
                        .font(.system(size: 40, weight: .heavy)).foregroundColor(textColor)
                }
                Spacer()
                Button { showScanner = true } label: {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(lightCard).frame(width: 44, height: 44)
                        .overlay(Image(systemName: "camera")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(textColor.opacity(0.75)))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 18)

            HStack(spacing: 10) {
                Text(dateText)
                    .font(.system(size: 18, weight: .medium)).foregroundColor(textColor.opacity(0.80))
                Button { withAnimation(.spring()) { showCalendar = true } } label: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(lightCard).frame(width: 44, height: 34)
                        .overlay(Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textColor.opacity(0.75)))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Mode Pills
    private var modePills: some View {
        HStack {
            modeButton(t("spend_btn"),   isActive: mode == .spend)   { mode = .spend }
            Spacer()
            modeButton(t("earning_btn"), isActive: mode == .earning) { mode = .earning }
        }
        .animation(.easeInOut(duration: 0.18), value: mode)
    }
    private func modeButton(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isActive ? .white : (isDark ? .white.opacity(0.9) : accent))
                .frame(width: 110, height: 34)
                .background(Capsule().fill(isActive ? accent : accent.opacity(isDark ? 0.20 : 0.12)))
        }
    }

    // MARK: - Input Card
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if eventText.isEmpty {
                        Text(t("event_hint"))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(cardTextColor.opacity(0.45))
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $eventText)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(cardTextColor)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .event)
                        .submitLabel(.next).onSubmit { focusedField = .note }
                }
                Spacer(minLength: 6)
                HStack(spacing: 6) {
                    Text("$").font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(cardTextColor.opacity(0.55))
                    ZStack(alignment: .trailing) {
                        if amountText.isEmpty {
                            Text("0.00")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(cardTextColor.opacity(0.45))
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $amountText)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(cardTextColor)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .amount)
                    }
                }
                .frame(width: 140, alignment: .trailing)
            }
            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text(t("note_hint"))
                        .font(.system(size: 18))
                        .foregroundStyle(cardTextColor.opacity(0.45))
                        .allowsHitTesting(false)
                }
                TextField("", text: $noteText, axis: .vertical)
                    .font(.system(size: 18))
                    .foregroundStyle(cardTextColor)
                    .lineLimit(2...6).focused($focusedField, equals: .note).submitLabel(.done)
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(isDark ? 0.25 : 0.10), radius: 16, x: 0, y: 10)
        .contentShape(Rectangle())
        .onTapGesture { if focusedField == nil { focusedField = .event } }
    }

    // MARK: - Size Labels
    private var sizeLabels: some View {
        HStack(spacing: 12) {
            sizePill(.major,    label: t("major_label"),    cardBg: Color(hex: "FFE4E6"), activeText: Color(hex: "C0392B"))
            sizePill(.moderate, label: t("moderate_label"), cardBg: Color(hex: "FFE1C2"), activeText: Color(hex: "C07000"))
            sizePill(.minor,    label: t("minor_label"),    cardBg: isDark ? Color(hex: "4A4A4C") : Color(hex: "D8D8D8"), activeText: isDark ? .white : Color(hex: "1A1A2E"))
        }
    }
    private func sizePill(_ size: AmountSize, label: String, cardBg: Color, activeText: Color) -> some View {
        let isActive = amountSize == size
        // 始终显示对应卡片颜色，选中时加深边框+文字加粗，未选中时透明度降低
        let pillBg:   Color = cardBg.opacity(isActive ? 1.0 : 0.45)
        let textColor: Color = isActive ? activeText : (isDark ? Color.white.opacity(0.55) : Color(hex: "1A1A2E").opacity(0.45))
        return Button { amountSize = size } label: {
            Text(label)
                .font(.system(size: 13, weight: isActive ? .bold : .medium))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Capsule().fill(pillBg))
                .overlay(
                    Capsule().strokeBorder(isActive ? cardBg : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: amountSize)
    }

    // MARK: - Picker Rows
    private var iconRow: some View {
        Button { showIconPicker = true } label: {
            HStack(spacing: 14) {
                // 左边图标区域（和 payMethod 行格式一致）
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Group {
                    if !customIconEmoji.isEmpty {
                        Text(customIconEmoji).font(.system(size: 20))
                    } else {
                        Image(systemName: hasSelectedIcon ? selectedIcon.symbol : "tag")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(accent)
                    }
                }
                }
                Text(t("category"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                Spacer()
                // 右侧显示当前选中值，和 payMethod 行一致
                Text(!customIconEmoji.isEmpty ? customIconEmoji : (hasSelectedIcon ? selectedIcon.label : t("category_placeholder")))
                    .font(.system(size: 14))
                    .foregroundColor(subColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(subColor)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(lightCard))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var payMethodRow: some View {
        pickerRow(
            icon: selectedPayMethod.icon, iconBg: accent.opacity(0.12), iconColor: accent,
            title: t("payment_method"), value: selectedPayMethod.displayName
        ) { withAnimation(.spring()) { showPayPicker = true } }
    }

    private var recurringRow: some View {
        let active = selectedRecurring != .none
        return Button { withAnimation(.spring()) { showRecurringPicker = true } } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: selectedRecurring.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("recurring_label_full"))
                        .font(.system(size: 16, weight: .medium)).foregroundColor(textColor)
                    if active {
                        Text(t("repeats_prefix") + " " + selectedRecurring.label.lowercased())
                            .font(.system(size: 11)).foregroundColor(accent)
                    }
                }
                Spacer()
                Text(selectedRecurring.label)
                    .font(.system(size: 14)).foregroundColor(active ? accent : subColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(subColor)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(active ? accent.opacity(0.07) : lightCard)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(active ? accent.opacity(0.30) : Color.clear, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    private func pickerRow(icon: String, iconBg: Color, iconColor: Color,
                           title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconBg).frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(iconColor)
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium)).foregroundColor(textColor)
                Spacer()
                Text(value).font(.system(size: 14)).foregroundColor(subColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(subColor)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(lightCard))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon Picker Sheet
    private var iconPickerSheet: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 40, height: 4).padding(.top, 14)
            Text(t("choose_icon")).font(.system(size: 18, weight: .bold)).foregroundColor(textColor)
            // 当前选中显示
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(accent).frame(width: 56, height: 56)
                    Image(systemName: selectedIcon.symbol)
                        .font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
                }
                Text(selectedIcon.label)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(accent)
            }
            // 横向滚轮
            iconWheelPicker
                .frame(height: 80)
            Button { hasSelectedIcon = true; withAnimation(.spring()) { showIconPicker = false } } label: {
                Text(t("done"))
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(accent))
            }
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
        .background((isDark ? Color(hex: "1C1C1E") : Color.white).ignoresSafeArea())
        .presentationDetents([.medium])
    }

    private var iconWheelPicker: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        Color.clear.frame(width: geo.size.width / 2 - 30)
                        ForEach(IconType.allCases, id: \.self) { icon in
                            GeometryReader { item in
                                let midX = geo.size.width / 2
                                let itemMidX = item.frame(in: .global).midX
                                let dist = abs(midX - itemMidX)
                                let scale: CGFloat = max(0.6, 1.0 - dist / 140 * 0.4)
                                let opacity: Double = max(0.35, 1.0 - Double(dist / 140) * 0.65)
                                Button {
                                    withAnimation(.spring(response: 0.3)) { selectedIcon = icon }
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == icon ? accent : lightCard)
                                                .frame(width: 52, height: 52)
                                            Image(systemName: icon.symbol)
                                                .font(.system(size: 22))
                                                .foregroundColor(selectedIcon == icon ? .white : textColor.opacity(0.75))
                                        }
                                        Text(icon.label)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(selectedIcon == icon ? accent : subColor)
                                            .lineLimit(1).frame(width: 52)
                                    }
                                    .scaleEffect(scale)
                                    .opacity(opacity)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 60, height: 75)
                            }
                            .frame(width: 60, height: 75)
                            .id(icon)
                        }
                        Color.clear.frame(width: geo.size.width / 2 - 30)
                    }
                }
                .onAppear {
                    proxy.scrollTo(selectedIcon, anchor: .center)
                }
            }
        }
    }

    // MARK: - Pay Method Sheet
    private var payMethodSheet: some View {
        PayMethodPickerSheet(selected: $selectedPayMethod, onDismiss: { showPayPicker = false })
    }

    // MARK: - Recurring Sheet
    private var recurringSheet: some View {
        RecurringPickerSheet(selected: $selectedRecurring, customDays: $customDays, customUnit: $customUnit, onDismiss: { showRecurringPicker = false })
    }

        // Generic list picker sheet
    private func pickerListSheet<T: Hashable>(
        title: String, items: [T], selected: T,
        onSelect: @escaping (T) -> Void,
        icon: @escaping (T) -> String,
        label: @escaping (T) -> String
    ) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 40, height: 4).padding(.top, 14).padding(.bottom, 16)
            Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(textColor).padding(.bottom, 12)
            VStack(spacing: 1) {
                ForEach(items, id: \.self) { item in
                    Button { onSelect(item) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: icon(item))
                                .font(.system(size: 18)).foregroundColor(accent).frame(width: 24)
                            Text(label(item))
                                .font(.system(size: 16, weight: .medium)).foregroundColor(textColor)
                            Spacer()
                            if selected == item {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold)).foregroundColor(accent)
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(selected == item ? accent.opacity(0.07) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if item != items.last { Divider().opacity(0.10).padding(.horizontal, 20) }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(lightCard))
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
        .background(RoundedRectangle(cornerRadius: 24).fill(isDark ? Color(hex: "1C1C1E") : Color.white))
    }

    // MARK: - Scanner Sheet
    private var scannerSheet: some View {
        Group {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerView(onResult: { noteText = $0 }, onDismiss: { showScanner = false })
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill").font(.system(size: 48)).foregroundColor(.gray)
                    Text(t("scanner_unavailable")).font(.system(size: 16)).foregroundColor(.gray)
                    Button(t("close")) { showScanner = false }
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bg.ignoresSafeArea())
            }
        }
    }

    // MARK: - Save
    private func saveEntry() {
        let category = eventText.trimmingCharacters(in: .whitespaces)
        guard !category.isEmpty else {
            showAlert = true; return
        }
        guard let amount = Double(amountText), amount > 0 else {
            showAlert = true; return
        }

        let sizeLabel: SizeLabel = {
            switch amountSize {
            case .major:    return .major
            case .moderate: return .moderate
            case .minor:    return .minor
            }
        }()

        // 计算自定义间隔天数
        let intervalDays: Int = {
            if selectedRecurring == .custom {
                let n = Int(customDays) ?? 30
                switch customUnit {
                case "weeks":  return n * 7
                case "months": return n * 30
                case "years":  return n * 365
                default:       return max(1, n)
                }
            }
            return 30
        }()

        // 设置下次到期日
        let dueDate: Date? = selectedRecurring == .none ? nil :
            ledgerStore.nextDueDate(after: selectedDate, frequency: selectedRecurring, customDays: intervalDays)

        let entry = Entry(
            date: selectedDate,
            category: category,
            note: noteText,
            payMethod: selectedPayMethod.rawValue,
            amount: amount,
            type: mode == .earning ? .earning : .expense,
            icon: selectedIcon,
            ledgerID: ledger.isTotal ? nil : ledger.id,
            sizeLabel: sizeLabel,
            recurring: selectedRecurring,
            nextDueDate: dueDate,
            customIntervalDays: intervalDays,
            customUnitStr: customUnit,
            customUnitCount: Int(customDays) ?? 1
        )
        ledgerStore.addEntry(entry)
        if entry.recurring != .none {
            ledgerStore.scheduleNotification(for: entry)
        }

        eventText         = ""
        noteText          = ""
        amountText        = ""
        amountSize        = .minor
        selectedIcon      = .meal
        selectedPayMethod = .cash
        selectedRecurring = .none
        selectedDate      = Date()
        focusedField      = nil

        // 跳转回 Home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSaveComplete?()
        }
    }

    // MARK: - Helpers
    private func isValidAmount(_ text: String) -> Bool {
        Double(text) != nil && (Double(text) ?? 0) > 0
    }
}

#Preview("Add + BottomBar") {
    PreviewWithBottomBar(active: .add) { AddEntryView() }
        .environmentObject(LedgerStore())
        .environmentObject(AppSettings())
}

// =============================================
// 独立 Struct — 避免 sheet 里 computed property 断链
// =============================================

struct PayMethodPickerSheet: View {
    @Binding var selected: PayMethod
    var onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lm = LocalizationManager.shared
    var isDark: Bool { colorScheme == .dark }
    var bg:   Color { Color(UIColor.systemBackground) }
    var card: Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F5F5F7") }
    var text: Color { isDark ? .white : .black.opacity(0.85) }
    var sub:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }
    let accent = Color(hex: "7E6AD6")

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4).padding(.top, 14).padding(.bottom, 16)
            Text(t("payment_method_label"))
                .font(.system(size: 18, weight: .bold)).foregroundColor(text).padding(.bottom, 12)
            VStack(spacing: 1) {
                ForEach(PayMethod.allCases, id: \.self) { method in
                    Button {
                        selected = method
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: method.icon)
                                .font(.system(size: 18)).foregroundColor(accent).frame(width: 24)
                            Text(method.displayName)
                                .font(.system(size: 16, weight: .medium)).foregroundColor(text)
                            Spacer()
                            if selected == method {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold)).foregroundColor(accent)
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(selected == method ? accent.opacity(0.07) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if method != PayMethod.allCases.last {
                        Divider().opacity(0.10).padding(.horizontal, 20)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(card))
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .background(bg.ignoresSafeArea())
    }
}

struct RecurringPickerSheet: View {
    @Binding var selected: RecurringFrequency
    @Binding var customDays: String
    @Binding var customUnit: String
    var onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lm = LocalizationManager.shared
    var isDark: Bool { colorScheme == .dark }
    var bg:   Color { Color(UIColor.systemBackground) }
    var card: Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F5F5F7") }
    var text: Color { isDark ? .white : .black.opacity(0.85) }
    var sub:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }
    let accent = Color(hex: "7E6AD6")
    @State private var showCustom = false
    // customDays and customUnit moved to AddEntryView

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4).padding(.top, 14).padding(.bottom, 12)
            Text(t("recurring_label_full"))
                .font(.system(size: 18, weight: .bold)).foregroundColor(text)
            Text(t("auto_log_desc"))
                .font(.system(size: 13)).foregroundColor(sub)
                .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.top, 4).padding(.bottom, 12)
            VStack(spacing: 1) {
                ForEach(RecurringFrequency.allCases.filter { $0 != .custom }, id: \.self) { freq in
                    Button {
                        selected = freq
                        showCustom = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: freq.icon)
                                .font(.system(size: 18)).foregroundColor(accent).frame(width: 24)
                            Text(freq.label)
                                .font(.system(size: 16, weight: .medium)).foregroundColor(text)
                            Spacer()
                            if selected == freq {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold)).foregroundColor(accent)
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(selected == freq ? accent.opacity(0.07) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.10).padding(.horizontal, 20)
                }
                // 自定义选项（展开/收起）
                Button { withAnimation { showCustom.toggle() } } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18)).foregroundColor(accent).frame(width: 24)
                        Text(t("custom_interval"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selected == .custom ? accent : text)
                        Spacer()
                        if selected == .custom {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold)).foregroundColor(accent)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(selected == .custom ? accent.opacity(0.07) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if showCustom {
                    VStack(alignment: .leading, spacing: 10) {
                        // 数字 + 单位
                        HStack(spacing: 8) {
                            Text(t("every_label")).font(.system(size: 15)).foregroundColor(sub)
                            TextField("1", text: $customDays)
                                .keyboardType(.numberPad)
                                .font(.system(size: 17, weight: .semibold)).foregroundStyle(text)
                                .multilineTextAlignment(.center).frame(width: 50)
                                .padding(.horizontal, 8).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(isDark ? Color(hex: "3A3A3C") : Color(hex: "F0EEF8")))
                            Spacer()
                            Button {
                                // Set 按钮：更新 selected 为 custom 并关闭
                                selected = .custom
                                onDismiss()
                            } label: {
                                Text(t("set_label"))
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(accent))
                            }
                        }
                        // 单位选择：独立一行，每个按钮占均等空间
                        HStack(spacing: 6) {
                            ForEach([("days", t("days_label")), ("weeks", t("weeks_label")), ("months", t("months_label")), ("years", t("years_label"))], id: \.0) { key, label in
                                Button { customUnit = key } label: {
                                    Text(label)
                                        .font(.system(size: 13, weight: customUnit == key ? .semibold : .regular))
                                        .foregroundColor(customUnit == key ? .white : sub)
                                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(customUnit == key ? accent : (isDark ? Color(hex: "3A3A3C") : Color(hex: "F0EEF8"))))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(card))
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .background(bg.ignoresSafeArea())
    }
}
