import SwiftUI

// ================================================
// LedgerSwitcherSheet
// ================================================

struct LedgerSwitcherSheet: View {
    @EnvironmentObject var ledgerStore: LedgerStore

    var onDismiss: () -> Void
    var onCreateNew: () -> Void

    private let accent = Color(hex: "7E6AD6")
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool { colorScheme == .dark }
    var bg:    Color { isDark ? Color(hex: "2C2C2E") : Color.white }
    var card:  Color { isDark ? Color(hex: "3A3A3C") : Color(hex: "F7F5F5") }
    var text:  Color { isDark ? .white : .black.opacity(0.85) }
    var sub:   Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.top, 12).padding(.bottom, 16)

            Text(t("select_ledger"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(text)
                .padding(.bottom, 14)

            VStack(spacing: 1) {
                ForEach(ledgerStore.ledgers.indices, id: \.self) { index in
                    let ledger = ledgerStore.ledgers[index]
                    Button {
                        ledgerStore.select(index: index)
                        onDismiss()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(ledger.id == ledgerStore.current.id ? accent.opacity(0.12) : card)
                                    .frame(width: 36, height: 36)
                                if ledger.isTotal {
                                    Image(systemName: "square.grid.2x2.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(ledger.id == ledgerStore.current.id ? accent : sub)
                                } else if ledger.emoji.hasPrefix("custom:") {
                                    Text(String(ledger.emoji.dropFirst(7))).font(.system(size: 18))
                                } else {
                                    Image(systemName: ledger.emoji.isEmpty ? "book.fill" : ledger.emoji)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ledger.id == ledgerStore.current.id ? accent : sub)
                                }
                            }
                            Text(ledger.isTotal ? t("total_label") : ledger.name)
                                .font(.system(size: 16, weight: ledger.id == ledgerStore.current.id ? .semibold : .regular))
                                .foregroundColor(text)
                            Spacer()
                            if ledger.id == ledgerStore.current.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(accent)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(ledger.id == ledgerStore.current.id ? accent.opacity(0.06) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < ledgerStore.ledgers.count - 1 {
                        Divider().opacity(0.10).padding(.horizontal, 16)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(card))
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Button {
                onCreateNew()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 16))
                    Text(t("create_new_ledger")).font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(accent.opacity(0.10)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
        .background(RoundedRectangle(cornerRadius: 24).fill(bg))
    }
}

// ================================================
// CalendarPickerSheet — 紧凑半屏，紫色主题，有记录日期显示小圆点
// ================================================

struct CalendarPickerSheet: View {
    @Binding var selectedMonth: Date
    var daysWithEntries: [Date]
    var onDismiss: () -> Void

    private let accent = Color(hex: "7E6AD6")
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool { colorScheme == .dark }
    var bg:   Color { isDark ? Color(hex: "1C1C1E") : Color.white }
    var text: Color { isDark ? .white : .black.opacity(0.85) }
    var sub:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    private let cal        = Calendar.current
    private var monthNames: [String] {
        [t("month_jan"),t("month_feb"),t("month_mar"),t("month_apr"),
         t("month_may"),t("month_jun"),t("month_jul"),t("month_aug"),
         t("month_sep"),t("month_oct"),t("month_nov"),t("month_dec")]
    }
    private let weekdays   = ["S","M","T","W","T","F","S"]

    @State private var displayDate: Date

    init(selectedMonth: Binding<Date>, daysWithEntries: [Date], onDismiss: @escaping () -> Void) {
        self._selectedMonth  = selectedMonth
        self.daysWithEntries = daysWithEntries
        self.onDismiss       = onDismiss
        self._displayDate    = State(initialValue: selectedMonth.wrappedValue)
    }

    private var year:  Int { cal.component(.year,  from: displayDate) }
    private var month: Int { cal.component(.month, from: displayDate) }

    private var firstOfMonth: Date {
        cal.date(from: DateComponents(year: year, month: month, day: 1))!
    }
    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
    }
    private var startWeekday: Int {
        (cal.component(.weekday, from: firstOfMonth) - 1 + 7) % 7
    }

    // 有记录的日期字符串集合
    private var entryDays: Set<String> {
        let df = DateFormatter(); df.dateFormat = "yyyy-M-d"
        return Set(daysWithEntries.map { df.string(from: $0) })
    }

    private func hasEntry(_ day: Int) -> Bool {
        let df = DateFormatter(); df.dateFormat = "yyyy-M-d"
        guard let d = cal.date(from: DateComponents(year: year, month: month, day: day)) else { return false }
        return entryDays.contains(df.string(from: d))
    }

    private func isSelected(_ day: Int) -> Bool {
        guard let d = cal.date(from: DateComponents(year: year, month: month, day: day)) else { return false }
        return cal.isDate(d, inSameDayAs: selectedMonth)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 14)

            // Month navigation
            HStack {
                Button { stepMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(accent.opacity(0.10)))
                }
                .buttonStyle(.plain)
                Spacer()
                Text("\(monthNames[month-1]) \(String(year))")
                    .font(.system(size: 17, weight: .bold)).foregroundColor(text)
                Spacer()
                Button { stepMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(accent.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24).padding(.bottom, 10)

            // Weekday header
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, wd in
                    Text(wd)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(sub)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8).padding(.bottom, 6)

            // Day grid
            let totalCells = startWeekday + daysInMonth
            let rows = Int(ceil(Double(totalCells) / 7.0))

            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { col in
                            let day = row * 7 + col - startWeekday + 1
                            if day < 1 || day > daysInMonth {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            } else {
                                Button {
                                    if let d = cal.date(from: DateComponents(year: year, month: month, day: day)) {
                                        selectedMonth = d
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
                                    }
                                } label: {
                                    VStack(spacing: 3) {
                                        ZStack {
                                            if isSelected(day) {
                                                Circle().fill(accent).frame(width: 34, height: 34)
                                            } else if hasEntry(day) {
                                                Circle().fill(accent.opacity(0.10)).frame(width: 34, height: 34)
                                            }
                                            Text("\(day)")
                                                .font(.system(size: 14, weight: isSelected(day) ? .bold : .regular))
                                                .foregroundColor(isSelected(day) ? .white : text)
                                        }
                                        // 紫色小圆点
                                        Circle()
                                            .fill(hasEntry(day) && !isSelected(day) ? accent : Color.clear)
                                            .frame(width: 4, height: 4)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8).padding(.bottom, 14)

            // Done button
            Button { onDismiss() } label: {
                Text(t("done"))
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(accent))
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .background(bg.ignoresSafeArea())
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    private func stepMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: displayDate) {
            withAnimation(.easeInOut(duration: 0.2)) { displayDate = d }
        }
    }
}
