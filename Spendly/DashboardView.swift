import SwiftUI

// MARK: - Identifiable wrapper for ledger edit sheet
struct EditingLedger: Identifiable {
    let id: Int  // ledger index
}

// MARK: - Filter/Sort options
enum EntryFilterType: String, CaseIterable {
    case all, expense, income
    var label: String {
        switch self {
        case .all:     return t("filter_all")
        case .expense: return t("filter_expense")
        case .income:  return t("filter_income")
        }
    }
}
enum EntrySortOrder: String, CaseIterable {
    case dateNew, dateOld, amountHigh, amountLow
    var label: String {
        switch self {
        case .dateNew:    return t("sort_date_new")
        case .dateOld:    return t("sort_date_old")
        case .amountHigh: return t("sort_amount_high")
        case .amountLow:  return t("sort_amount_low")
        }
    }
}

// MARK: - DashboardView
struct DashboardView: View {
    @EnvironmentObject var ledgerStore: LedgerStore
    @EnvironmentObject var appSettings: AppSettings

    // Tab switching callback for "Save → go Home"
    var onGoHome: (() -> Void)? = nil

    private let accent    = Color(hex: "7E6AD6")
    private let plusBg    = Color(hex: "DCCAF6")

    var isDark:    Bool  { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color.white.opacity(0.90) }
    var card2:     Color { isDark ? Color(hex: "3A3A3C") : Color(hex: "F0EEF8") }
    var textColor: Color { isDark ? .white : Color(hex: "1A1A2E") }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    @StateObject private var vm = DashboardVM()

    @State private var showLedgerSwitcher      = false
    @State private var showCreateLedger        = false
    @State private var editingLedger: EditingLedger? = nil
    @State private var editMode                = false
    @State private var editingEntry: Entry?    = nil
    @State private var showDeleteAlert         = false
    @State private var entryToDelete: Entry?   = nil
    @State private var showUndoBanner          = false
    @State private var showDeleteLedgerAlert   = false
    @State private var pendingDeleteLedgerIndex: Int? = nil
    @State private var showFilterSheet         = false

    // Filter & Sort state
    @State private var filterType:  EntryFilterType = .all
    @State private var sortOrder:   EntrySortOrder  = .dateNew

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerArea
                        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 14)
                    ledgerCarousel.padding(.bottom, 18)
                    summaryCard.padding(.horizontal, 20).padding(.bottom, 20)
                    entriesSection.padding(.horizontal, 20)
                    Spacer().frame(height: 120)
                }
            }

            // Ledger Switcher overlay
            if showLedgerSwitcher {
                overlayBackground { showLedgerSwitcher = false }
                VStack {
                    Spacer()
                    LedgerSwitcherSheet(
                        onDismiss: { withAnimation(.spring()) { showLedgerSwitcher = false } },
                        onCreateNew: { showCreateLedger = true; showLedgerSwitcher = false }
                    )
                    .environmentObject(ledgerStore)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 8).padding(.bottom, 100)
                }
                .ignoresSafeArea(edges: .bottom)
            }

            // Filter sheet overlay
            if showFilterSheet {
                overlayBackground { showFilterSheet = false }
                VStack {
                    Spacer()
                    filterSortSheet
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 8).padding(.bottom, 100)
                }
                .ignoresSafeArea(edges: .bottom)
            }

            // Undo Banner
            if showUndoBanner {
                VStack {
                    Spacer()
                    HStack {
                        Text(t("entry_deleted"))
                            .font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                        Spacer()
                        Button(t("undo_label")) {
                            ledgerStore.undoDelete()
                            withAnimation { showUndoBanner = false }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "DCCAF6"))
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "2C2C2E")))
                    .padding(.horizontal, 20).padding(.bottom, 110)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: showUndoBanner)
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showLedgerSwitcher)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFilterSheet)
        .sheet(isPresented: $showCreateLedger) {
            CreateLedgerView { name, emoji in
                ledgerStore.addLedger(name: name, emoji: emoji)
                showCreateLedger = false
            }
        }
        .sheet(item: $editingLedger) { item in
            let idx = item.id
            if idx < ledgerStore.ledgers.count {
                EditLedgerView(ledger: ledgerStore.ledgers[idx]) { name, emoji in
                    ledgerStore.ledgers[idx].name  = name
                    ledgerStore.ledgers[idx].emoji = emoji
                    ledgerStore.saveLedgers()
                    editingLedger = nil
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry,
                onSave: { updated in
                    ledgerStore.updateEntry(updated)
                    editingEntry = nil
                },
                onDelete: { toDelete in
                    entryToDelete = toDelete
                    editingEntry  = nil
                    showDeleteAlert = true
                })
            .environmentObject(appSettings)
        }
        .alert(t("delete"), isPresented: $showDeleteAlert) {
            Button(t("delete"), role: .destructive) {
                if let e = entryToDelete {
                    ledgerStore.deleteEntry(e)
                    withAnimation { showUndoBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation { showUndoBanner = false }
                    }
                }
            }
            Button(t("cancel"), role: .cancel) {}
        } message: { Text(t("delete_record_confirm")) }
        .alert(t("delete_ledger_title"), isPresented: $showDeleteLedgerAlert) {
            Button(t("delete_ledger_and_records"), role: .destructive) {
                if let idx = pendingDeleteLedgerIndex {
                    ledgerStore.deleteLedger(at: idx, deleteEntries: true)
                    pendingDeleteLedgerIndex = nil
                }
            }
            Button(t("delete_ledger_only")) {
                if let idx = pendingDeleteLedgerIndex {
                    ledgerStore.deleteLedger(at: idx, deleteEntries: false)
                    pendingDeleteLedgerIndex = nil
                }
            }
            Button(t("cancel"), role: .cancel) { pendingDeleteLedgerIndex = nil }
        } message: {
            if let idx = pendingDeleteLedgerIndex, idx < ledgerStore.ledgers.count {
                let name  = ledgerStore.ledgers[idx].name
                let count = ledgerStore.entries.filter { $0.ledgerID == ledgerStore.ledgers[idx].id }.count
                Text("Delete \"\(name)\"? It has \(count) \(t("delete_ledger_message")). Keep records (move to All) or delete them too.")
            } else {
                Text(t("are_you_sure"))
            }
        }
    }

    // MARK: - Overlay background helper
    private func overlayBackground(onTap: @escaping () -> Void) -> some View {
        Color.black.opacity(0.30).ignoresSafeArea()
            .onTapGesture { withAnimation(.spring()) { onTap() } }
    }

    // MARK: - Header
    private var headerArea: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.monthText())
                    .font(.system(size: 14, weight: .medium)).foregroundColor(subColor)
                Text(ledgerStore.current.isTotal ? t("all_ledgers_title") : ledgerStore.current.name)
                    .font(.system(size: 28, weight: .heavy)).foregroundColor(textColor)
            }
            Spacer()
            HStack(spacing: 10) {
                // Filter button (replaces "...")
                Button {
                    withAnimation(.spring()) { showFilterSheet = true }
                } label: {
                    ZStack {
                        Capsule().fill(accent.opacity(0.12)).frame(width: 44, height: 34)
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        if filterType != .all || sortOrder != .dateNew {
                            Circle().fill(accent).frame(width: 8, height: 8)
                                .offset(x: 14, y: -10)
                        }
                    }
                }
                // Edit mode
                Button {
                    withAnimation(.spring(response: 0.3)) { editMode.toggle() }
                } label: {
                    Text(editMode ? t("done") : t("edit"))
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(accent.opacity(0.12)))
                }
            }
        }
    }

    // MARK: - Ledger Carousel
    private var ledgerCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ledgerStore.ledgers.indices, id: \.self) { idx in
                    ledgerCard(ledger: ledgerStore.ledgers[idx], index: idx)
                }
                // Add new
                Button { showCreateLedger = true } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(card2).frame(width: 64, height: 64)
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(accent.opacity(0.7))
                        }
                        Text(t("new_label"))
                            .font(.system(size: 11, weight: .medium)).foregroundColor(subColor)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }

    private func ledgerCard(ledger: Ledger, index: Int) -> some View {
        let isSelected = ledgerStore.selectedIndex == index
        return Button {
            withAnimation(.spring(response: 0.3)) { ledgerStore.select(index: index) }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? accent : card)
                        .frame(width: 64, height: 64)
                        .shadow(color: isSelected ? accent.opacity(0.35) : .black.opacity(0.06),
                                radius: isSelected ? 10 : 6, x: 0, y: 4)

                    if ledger.isTotal {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 26))
                            .foregroundColor(isSelected ? .white : accent)
                    } else if ledger.emoji.hasPrefix("custom:") {
                        Text(String(ledger.emoji.dropFirst(7)))
                            .font(.system(size: 24))
                    } else {
                        Image(systemName: ledger.emoji.isEmpty ? "book.fill" : ledger.emoji)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(isSelected ? .white : accent)
                    }

                    if ledger.isPinned && !ledger.isTotal {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : accent)
                            .offset(x: 22, y: -22)
                    }

                    if editMode && !ledger.isTotal {
                        // 左上角 — 编辑
                        Button {
                            editingLedger = EditingLedger(id: index)
                        } label: {
                            ZStack {
                                Circle().fill(accent).frame(width: 20, height: 20)
                                Image(systemName: "pencil")
                                    .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .offset(x: 22, y: -22)
                        // 右上角 — 删除
                        Button {
                            pendingDeleteLedgerIndex = index
                            showDeleteLedgerAlert = true
                        } label: {
                            ZStack {
                                Circle().fill(Color.red).frame(width: 20, height: 20)
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .offset(x: -22, y: -22)
                    }
                }
                Text(ledger.isTotal ? t("all_label") : ledger.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? accent : subColor)
                    .lineLimit(1).frame(width: 64)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !ledger.isTotal {
                Button {
                        editingLedger = EditingLedger(id: index)
                    } label: {
                    Label(t("edit_ledger"), systemImage: "pencil")
                }
                Button {
                    ledgerStore.setDefault(index: index)
                } label: {
                    Label(ledger.isPinned ? t("current_default") : t("set_default_ledger"),
                          systemImage: ledger.isPinned ? "star.fill" : "star")
                }
                .disabled(ledger.isPinned)
                Divider()
                Button(role: .destructive) {
                    pendingDeleteLedgerIndex = index
                    showDeleteLedgerAlert = true
                } label: {
                    Label(t("delete"), systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        let ledger   = ledgerStore.current
        let earnings = vm.totalEarnings(entries: ledgerStore.entries, for: ledger)
        let expenses = vm.totalExpenses(entries: ledgerStore.entries, for: ledger)
        let net      = vm.totalNet(entries: ledgerStore.entries, for: ledger)

        return VStack(spacing: 0) {
            HStack {
                Button { stepMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                }
                Spacer()
                Text(vm.monthText())
                    .font(.system(size: 15, weight: .bold)).foregroundColor(textColor)
                Spacer()
                Button { stepMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                }
            }
            .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 14)

            Divider().opacity(0.08).padding(.horizontal, 16)

            HStack(spacing: 0) {
                summaryBlock(title: t("earnings"), value: earnings,  color: Color(hex: "34C759"))
                Divider().frame(height: 40).opacity(0.12)
                summaryBlock(title: t("spend"),    value: expenses,  color: Color(hex: "FF6B6B"))
                Divider().frame(height: 40).opacity(0.12)
                summaryBlock(title: t("net"),      value: net,       color: net >= 0 ? Color(hex: "34C759") : Color(hex: "FF6B6B"), showSign: true)
            }
            .padding(.vertical, 16)
        }
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(card))
        .shadow(color: .black.opacity(isDark ? 0.25 : 0.06), radius: 12, x: 0, y: 6)
    }

    private func summaryBlock(title: String, value: Double, color: Color, showSign: Bool = false) -> some View {
        VStack(spacing: 5) {
            Text(title).font(.system(size: 12)).foregroundColor(subColor)
            Text((showSign && value >= 0 ? "+" : "") + formatMoney(value))
                .font(.system(size: 20, weight: .bold)).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Entries Section
    // 显式接受所有依赖参数，确保 SwiftUI 能追踪变化
    private func computeEntries(
        filterType: EntryFilterType,
        sortOrder: EntrySortOrder,
        ledger: Ledger,
        allEntries: [Entry]
    ) -> [(title: String, items: [Entry])] {
        let cal = Calendar.current

        // 1. 按账本过滤
        let ledgerEntries = ledger.isTotal
            ? allEntries
            : allEntries.filter { $0.ledgerID == ledger.id }

        // 选中月份的最后一刻（不显示未来月份的记录）
        let endOfSelectedMonth: Date = {
            var comps = cal.dateComponents([.year, .month], from: vm.selectedMonth)
            comps.month! += 1
            return cal.date(from: comps) ?? Date()
        }()

        var flat = ledgerEntries.filter { $0.date < endOfSelectedMonth }

        // 2. 类型筛选
        if filterType != .all {
            flat = flat.filter { filterType == .expense ? $0.type == .expense : $0.type == .earning }
        }

        // 3. 全局排序
        switch sortOrder {
        case .dateNew:    flat.sort { $0.date > $1.date }
        case .dateOld:    flat.sort { $0.date < $1.date }
        case .amountHigh: flat.sort { $0.amount > $1.amount }
        case .amountLow:  flat.sort { $0.amount < $1.amount }
        }

        // 4. 分组
        let isAmountSort = (sortOrder == .amountHigh || sortOrder == .amountLow)
        if isAmountSort {
            return flat.map { entry in
                (title: vm.dayTitle(cal.startOfDay(for: entry.date)), items: [entry])
            }
        } else {
            var result: [(title: String, items: [Entry])] = []
            var seen: [String: Int] = [:]
            for entry in flat {
                let title = vm.dayTitle(cal.startOfDay(for: entry.date))
                if let idx = seen[title] { result[idx].items.append(entry) }
                else { seen[title] = result.count; result.append((title: title, items: [entry])) }
            }
            return result
        }
    }

    private var entriesSection: some View {
        // 显式读取 ledgerStore 属性，确保 SwiftUI 追踪账本切换、记录变化
        let currentLedger = ledgerStore.current
        let allEntries = ledgerStore.entries
        let sorted = computeEntries(
            filterType: filterType,
            sortOrder: sortOrder,
            ledger: currentLedger,
            allEntries: allEntries
        )

        return VStack(alignment: .leading, spacing: 16) {
            if sorted.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 38)).foregroundColor(subColor.opacity(0.35))
                    Text(t("no_entries"))
                        .font(.system(size: 16)).foregroundColor(subColor)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 48)
            } else {
                let isAmountSort = (sortOrder == .amountHigh || sortOrder == .amountLow)
                ForEach(Array(sorted.enumerated()), id: \.offset) { _, group in
                    VStack(alignment: .leading, spacing: 8) {
                        if !isAmountSort {
                            Text(group.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(subColor).padding(.leading, 4)
                        }
                        VStack(spacing: 8) {
                            ForEach(group.items) { entry in
                                entryRow(entry: entry, dateLabel: isAmountSort ? group.title : nil)
                                    .background(entryCardBg(entry))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: .black.opacity(isDark ? 0.2 : 0.06), radius: 8, x: 0, y: 4)
                                    .onTapGesture { if editMode { editingEntry = entry } }
                            }
                        }
                    }
                }
            }
        }
    }

    private func entryRow(entry: Entry, dateLabel: String? = nil) -> some View {
        // 大额/中额背景是浅色，文字用深色；小额跟随系统
        let onColoredBg = entry.sizeLabel != .minor
        let rowText: Color = onColoredBg ? Color(hex: "1A1A2E") : textColor
        let rowSub:  Color = onColoredBg ? Color(hex: "1A1A2E").opacity(0.55) : subColor

        let payDisplay: String? = {
            guard !entry.payMethod.isEmpty && entry.payMethod != PayMethod.cash.rawValue else { return nil }
            return PayMethod(rawValue: entry.payMethod)?.displayName ?? entry.payMethod
        }()

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(entry.type == .earning
                          ? Color(hex: "34C759").opacity(0.15)
                          : accent.opacity(0.13))
                    .frame(width: 42, height: 42)
                Image(systemName: entry.icon.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(entry.type == .earning ? Color(hex: "2A9E48") : accent)
            }

            // 左边：名称、备注、日期标注（金额排序时）、recurring
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.category)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(rowText)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.system(size: 12)).foregroundColor(rowSub).lineLimit(1)
                }
                if let dl = dateLabel {
                    Text(dl)
                        .font(.system(size: 11)).foregroundColor(rowSub.opacity(0.8))
                }
                if entry.recurring != .none {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 9, weight: .bold))
                        // 自定义间隔：显示具体数量和单位
                        if entry.recurring == .custom {
                            let unitLabel: String = {
                                switch entry.customUnitStr {
                                case "weeks":  return t("weeks_label")
                                case "months": return t("months_label")
                                case "years":  return t("years_label")
                                default:       return t("days_label")
                                }
                            }()
                            Text("Every \(entry.customUnitCount) \(unitLabel)")
                                .font(.system(size: 10, weight: .semibold))
                        } else {
                            Text(entry.recurring.label).font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .foregroundColor(accent)
                }
            }

            Spacer()

            // 右边：金额 + 支付方式
            VStack(alignment: .trailing, spacing: 3) {
                Text((entry.type == .earning ? "+" : "-") + formatMoney(entry.amount))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(entry.type == .earning ? Color(hex: "2A9E48") : Color(hex: "D94040"))
                if let pay = payDisplay {
                    Text(pay)
                        .font(.system(size: 11)).foregroundColor(rowSub)
                }
            }

            if editMode {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 20)).foregroundColor(accent.opacity(0.6))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    // 每条记录的卡片背景色 — 大额粉色、中额橙色、小额默认卡片色
    private func entryCardBg(_ entry: Entry) -> Color {
        switch entry.sizeLabel {
        case .major:    return Color(hex: "FFE4E6")  // 锁死粉色
        case .moderate: return Color(hex: "FFF0DC")  // 锁死橙色
        case .minor:    return card
        }
    }

    // sizeBadge — 大额粉色、中额橙色，颜色锁死不随深浅色变
    private func sizeBadge(_ size: SizeLabel) -> some View {
        // 卡片已经变色了，不需要角标
        EmptyView()
    }

    // MARK: - Filter/Sort Sheet
    private var filterSortSheet: some View {
        FilterSortSheetView(
            filterType: $filterType,
            sortOrder:  $sortOrder,
            onClose:    { withAnimation(.spring()) { showFilterSheet = false } }
        )
    }

    // MARK: - Helpers
    private func stepMonth(_ delta: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: delta, to: vm.selectedMonth) {
            vm.selectedMonth = d
        }
    }

    private func formatMoney(_ v: Double) -> String {
        let abs_v = abs(v)
        let sign = v < 0 ? "-" : ""
        if abs_v >= 1_000_000 {
            // 精确到小数后3位，去掉尾部零
            let m = abs_v / 1_000_000
            let s = String(format: "%.3f", m).replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
            return "\(sign)$\(s)M"
        } else if abs_v >= 1_000 {
            let k = abs_v / 1_000
            let s = String(format: "%.3f", k).replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
            return "\(sign)$\(s)k"
        }
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"
        f.maximumFractionDigits = 2; f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - EditEntrySheet
struct EditEntrySheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var lm = LocalizationManager.shared

    var entry: Entry
    var onSave: (Entry) -> Void
    var onDelete: (Entry) -> Void

    private let accent = Color(hex: "7E6AD6")
    var isDark:    Bool  { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    @State private var category: String
    @State private var note: String
    @State private var amountText: String
    @State private var entryType: EntryType
    @State private var selectedIcon: IconType
    @State private var sizeLabel: SizeLabel
    @State private var date: Date
    @State private var selectedPayMethod: PayMethod
    @State private var selectedRecurring: RecurringFrequency
    @State private var showDeleteConfirm  = false
    @State private var showIconPickerSheet = false

    init(entry: Entry, onSave: @escaping (Entry) -> Void, onDelete: @escaping (Entry) -> Void) {
        self.entry    = entry
        self.onSave   = onSave
        self.onDelete = onDelete
        _category     = State(initialValue: entry.category)
        _note         = State(initialValue: entry.note)
        _amountText   = State(initialValue: {
            let v = entry.amount
            return v.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(v)) : String(format: "%.2f", v)
        }())
        _entryType         = State(initialValue: entry.type)
        _selectedIcon      = State(initialValue: entry.icon)
        _sizeLabel         = State(initialValue: entry.sizeLabel)
        _date              = State(initialValue: entry.date)
        _selectedPayMethod = State(initialValue: PayMethod(rawValue: entry.payMethod) ?? .cash)
        _selectedRecurring = State(initialValue: entry.recurring)
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.gray.opacity(0.35))
                    .frame(width: 40, height: 4).padding(.top, 14).padding(.bottom, 16)

                Text(t("edit_entry_title"))
                    .font(.system(size: 20, weight: .bold)).foregroundColor(textColor)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Type toggle
                        HStack(spacing: 0) {
                            typeButton(.expense, label: t("spend_label"))
                            typeButton(.earning, label: t("earning_label"))
                        }
                        .background(RoundedRectangle(cornerRadius: 12).fill(card))

                        // Category
                        field(label: t("category")) {
                            TextField(t("eg_lunch"), text: $category).foregroundColor(textColor)
                        }

                        // Amount
                        field(label: t("amount")) {
                            HStack {
                                Text("$").foregroundColor(subColor)
                                TextField("0.00", text: $amountText)
                                    .keyboardType(.decimalPad).foregroundColor(textColor)
                            }
                        }

                        // Note
                        field(label: t("note")) {
                            TextField(t("optional_note"), text: $note, axis: .vertical)
                                .lineLimit(1...4).foregroundColor(textColor)
                        }

                        // Size label
                        VStack(alignment: .leading, spacing: 8) {
                            Text(t("size_label")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                            HStack(spacing: 8) {
                                sizeLabelButton(.major,    label: t("major_label"),    textClr: Color(hex: "FF6B6B"), bgClr: Color(hex: "FFE4E6"))
                                sizeLabelButton(.moderate, label: t("moderate_label"), textClr: Color(hex: "FF9500"), bgClr: Color(hex: "FFE8C0"))
                                sizeLabelButton(.minor,    label: t("minor_label"),    textClr: subColor,             bgClr: card)
                            }
                        }

                        // Date
                        HStack {
                            Text(t("date")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor)
                            Spacer()
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .labelsHidden().tint(accent)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(card))

                        // Payment Method
                        VStack(alignment: .leading, spacing: 8) {
                            Text(t("payment_method")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                            VStack(spacing: 1) {
                                ForEach(PayMethod.allCases, id: \.self) { method in
                                    Button { selectedPayMethod = method } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: method.icon)
                                                .font(.system(size: 16)).foregroundColor(accent).frame(width: 22)
                                            Text(method.displayName)
                                                .font(.system(size: 15)).foregroundColor(textColor)
                                            Spacer()
                                            if selectedPayMethod == method {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold)).foregroundColor(accent)
                                            }
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 12)
                                        .background(selectedPayMethod == method ? accent.opacity(0.07) : Color.clear)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    if method != PayMethod.allCases.last {
                                        Divider().opacity(0.08).padding(.horizontal, 14)
                                    }
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 12).fill(card))
                        }

                        // Recurring
                        VStack(alignment: .leading, spacing: 8) {
                            Text(t("recurring_label")).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
                            VStack(spacing: 1) {
                                ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                    Button { selectedRecurring = freq } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: freq.icon)
                                                .font(.system(size: 16)).foregroundColor(accent).frame(width: 22)
                                            Text(freq.label)
                                                .font(.system(size: 15)).foregroundColor(textColor)
                                            Spacer()
                                            if selectedRecurring == freq {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold)).foregroundColor(accent)
                                            }
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 12)
                                        .background(selectedRecurring == freq ? accent.opacity(0.07) : Color.clear)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    if freq != RecurringFrequency.allCases.last {
                                        Divider().opacity(0.08).padding(.horizontal, 14)
                                    }
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 12).fill(card))
                        }

                        // Icon picker — tap to open wheel sheet
                        Button { showIconPickerSheet = true } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(accent.opacity(0.12)).frame(width: 36, height: 36)
                                    Image(systemName: selectedIcon.symbol)
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(accent)
                                }
                                Text(selectedIcon.label)
                                    .font(.system(size: 15, weight: .medium)).foregroundColor(textColor)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold)).foregroundColor(subColor)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 12).fill(card))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        // Save
                        Button {
                            guard let amount = Double(amountText), amount > 0 else { return }
                            var updated = entry
                            updated.category  = category.trimmingCharacters(in: .whitespaces)
                            updated.note      = note
                            updated.amount    = amount
                            updated.type      = entryType
                            updated.icon      = selectedIcon
                            updated.sizeLabel = sizeLabel
                            updated.date      = date
                            updated.payMethod = selectedPayMethod.rawValue
                            updated.recurring = selectedRecurring
                            onSave(updated)
                        } label: {
                            Text(t("save_changes"))
                                .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(RoundedRectangle(cornerRadius: 14).fill(accent))
                        }

                        // Delete
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text(t("delete"))
                                .font(.system(size: 17, weight: .semibold)).foregroundColor(.red)
                                .frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.10)))
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .sheet(isPresented: $showIconPickerSheet) {
            editIconPickerSheet
        }
        .alert(t("delete"), isPresented: $showDeleteConfirm) {
            Button(t("delete"), role: .destructive) { onDelete(entry) }
            Button(t("cancel"), role: .cancel) {}
        } message: { Text(t("delete_record_confirm")) }
    }

    private func typeButton(_ type: EntryType, label: String) -> some View {
        Button { entryType = type } label: {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(entryType == type ? .white : subColor)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(entryType == type ? accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: entryType)
    }

    private func sizeLabelButton(_ sl: SizeLabel, label: String, textClr: Color, bgClr: Color) -> some View {
        Button { sizeLabel = sl } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(sizeLabel == sl ? textClr : subColor)
                .frame(maxWidth: .infinity).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(sizeLabel == sl ? bgClr : card)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(sizeLabel == sl ? textClr.opacity(0.4) : Color.clear, lineWidth: 1.5)))
        }
        .buttonStyle(.plain)
    }

    private var editIconPickerSheet: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4).padding(.top, 14).padding(.bottom, 16)
            Text(t("choose_icon"))
                .font(.system(size: 18, weight: .bold)).foregroundColor(textColor).padding(.bottom, 12)
            ZStack {
                Circle().fill(accent).frame(width: 56, height: 56)
                Image(systemName: selectedIcon.symbol)
                    .font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
            }
            .padding(.bottom, 4)
            Text(selectedIcon.label)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(accent).padding(.bottom, 16)
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            Color.clear.frame(width: geo.size.width / 2 - 32)
                            ForEach(IconType.allCases, id: \.self) { icon in
                                GeometryReader { item in
                                    let midX    = geo.size.width / 2
                                    let itemMid = item.frame(in: .global).midX
                                    let dist    = abs(midX - itemMid)
                                    let scale   = max(0.58, 1.0 - dist / 120 * 0.42)
                                    let opac    = max(0.30, 1.0 - Double(dist / 120) * 0.70)
                                    Button {
                                        withAnimation(.spring(response: 0.25)) { selectedIcon = icon }
                                    } label: {
                                        VStack(spacing: 5) {
                                            ZStack {
                                                Circle().fill(selectedIcon == icon ? accent : card).frame(width: 56, height: 56)
                                                Image(systemName: icon.symbol)
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundColor(selectedIcon == icon ? .white : subColor)
                                            }
                                            Text(icon.label)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(selectedIcon == icon ? accent : subColor).lineLimit(1)
                                        }
                                        .scaleEffect(scale).opacity(opac)
                                    }
                                    .buttonStyle(.plain).frame(width: 64, height: 85)
                                }
                                .frame(width: 64, height: 85).id(icon)
                            }
                            Color.clear.frame(width: geo.size.width / 2 - 32)
                        }
                    }
                    .onAppear { proxy.scrollTo(selectedIcon, anchor: .center) }
                }
            }
            .frame(height: 90).padding(.bottom, 20)
            Button { showIconPickerSheet = false } label: {
                Text(t("done"))
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(accent))
            }
            .padding(.horizontal, 24).padding(.bottom, 30)
        }
        .background((isDark ? Color(hex: "1C1C1E") : Color.white).ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(subColor).padding(.horizontal, 4)
            content()
                .font(.system(size: 17)).padding(.horizontal, 16).padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14).fill(card))
        }
    }
}

#Preview("Dashboard") {
    let userStore   = UserStore(phone: "1234567890")
    let ledgerStore = LedgerStore(userStore: userStore)
    ledgerStore.addEntry(Entry(date: Date(), category: "Lunch", note: "Pizza", payMethod: "Apple Pay",
                               amount: 15, type: .expense, icon: .meal, sizeLabel: .major))
    ledgerStore.addEntry(Entry(date: Date(), category: "Salary", note: "",
                               payMethod: "", amount: 100000, type: .earning, icon: .earning, sizeLabel: .major))
    return DashboardView()
        .environmentObject(AppSettings())
        .environmentObject(ledgerStore)
}

// MARK: - Filter/Sort Sheet (independent struct for reliable @State updates)
struct FilterSortSheetView: View {
    @Binding var filterType: EntryFilterType
    @Binding var sortOrder:  EntrySortOrder
    var onClose: () -> Void

    // Local draft state — only written to bindings on Apply
    @State private var draftFilter: EntryFilterType = .all
    @State private var draftSort:   EntrySortOrder  = .dateNew

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lm = LocalizationManager.shared

    var isDark: Bool { colorScheme == .dark }
    var sheetBg:   Color { isDark ? Color(hex: "1C1C1E") : Color.white }
    var sheetCard: Color { isDark ? Color(hex: "2C2C2E") : Color(hex: "F7F5F5") }
    var textColor: Color { isDark ? .white : .black.opacity(0.85) }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }
    let accent = Color(hex: "7E6AD6")

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 16)

            Text(t("sort_filter"))
                .font(.system(size: 18, weight: .bold)).foregroundColor(textColor)
                .padding(.bottom, 16)

            // Filter by type
            VStack(alignment: .leading, spacing: 8) {
                Text(t("filter_type"))
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(subColor)
                    .padding(.horizontal, 4)
                HStack(spacing: 8) {
                    ForEach(EntryFilterType.allCases, id: \.self) { type in
                        Button { draftFilter = type } label: {
                            Text(type.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(draftFilter == type ? .white : textColor)
                                .padding(.horizontal, 16).padding(.vertical, 9)
                                .background(Capsule().fill(draftFilter == type ? accent : sheetCard))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 16)

            // Sort order
            VStack(alignment: .leading, spacing: 8) {
                Text(t("sort_by"))
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(subColor)
                    .padding(.horizontal, 4)
                VStack(spacing: 1) {
                    ForEach(EntrySortOrder.allCases, id: \.self) { order in
                        Button { draftSort = order } label: {
                            HStack {
                                Text(order.label)
                                    .font(.system(size: 15)).foregroundColor(textColor)
                                Spacer()
                                if draftSort == order {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold)).foregroundColor(accent)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 13)
                            .background(draftSort == order ? accent.opacity(0.07) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if order != EntrySortOrder.allCases.last {
                            Divider().opacity(0.10).padding(.horizontal, 16)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(sheetCard))
            }
            .padding(.horizontal, 20).padding(.bottom, 16)

            // Apply / Reset
            HStack(spacing: 12) {
                Button {
                    draftFilter = .all
                    draftSort   = .dateNew
                    filterType  = .all
                    sortOrder   = .dateNew
                    onClose()
                } label: {
                    Text(t("reset"))
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(accent)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(accent.opacity(0.10)))
                }
                .buttonStyle(.plain)

                Button {
                    filterType = draftFilter
                    sortOrder  = draftSort
                    onClose()
                } label: {
                    Text(t("apply"))
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(accent))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
        .background(RoundedRectangle(cornerRadius: 24).fill(sheetBg))
        .onAppear {
            // 打开时把当前值同步到 draft
            draftFilter = filterType
            draftSort   = sortOrder
        }
    }
}
