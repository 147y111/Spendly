//
//  AnalyticsView.swift
//  Spendly copy
//
//  Created by Qi on 3/14/26.
//


//
//  AnalyticsView.swift
//  SpendlyFinal
//
//  Created by Qi on 3/10/26.
//


import SwiftUI

// MARK: - AnalyticsView

struct AnalyticsView: View {
    @EnvironmentObject var ledgerStore: LedgerStore
    @EnvironmentObject var appSettings: AppSettings

    private let accent       = Color(hex: "7E6AD6")
    private let incomeColor  = Color(hex: "34C759")
    private let expenseColor = Color(hex: "FF6B6B")

    var isDark:    Bool  { appSettings.isDarkMode }
    var bg:        Color { isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFAFA") }
    var card:      Color { isDark ? Color(hex: "2C2C2E") : Color.white }
    var card2:     Color { isDark ? Color(hex: "3A3A3C") : Color(hex: "F0EEF8") }
    var textColor: Color { isDark ? .white : Color(hex: "1A1A2E") }
    var subColor:  Color { isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40) }

    @State private var selectedYear:     Int  = Calendar.current.component(.year,  from: Date())
    @State private var selectedMonth:    Int  = Calendar.current.component(.month, from: Date())
    @State private var selectedLedgerID: UUID? = nil

    private var monthLabels: [String] {
        [t("month_jan"),t("month_feb"),t("month_mar"),t("month_apr"),
         t("month_may"),t("month_jun"),t("month_jul"),t("month_aug"),
         t("month_sep"),t("month_oct"),t("month_nov"),t("month_dec")]
    }
    private let cal = Calendar.current

    private let pieColors: [Color] = [
        Color(hex: "7E6AD6"), Color(hex: "FF6B9D"), Color(hex: "FFB347"),
        Color(hex: "4ECDC4"), Color(hex: "45B7D1"), Color(hex: "96CEB4"),
        Color(hex: "DDA0DD"), Color(hex: "F7DC6F"), Color(hex: "85C1E9"),
        Color(hex: "BB8FCE"), Color(hex: "98D8C8"), Color(hex: "FFEAA7")
    ]

    // MARK: - Derived data

    private var filtered: [Entry] {
        guard let id = selectedLedgerID else { return ledgerStore.entries }
        return ledgerStore.entries.filter { $0.ledgerID == id }
    }

    private var monthEntries:  [Entry] {
        filtered.filter {
            cal.component(.year,  from: $0.date) == selectedYear &&
            cal.component(.month, from: $0.date) == selectedMonth
        }
    }
    private var monthExpenses: [Entry] { monthEntries.filter { $0.type == .expense } }
    private var monthEarnings: [Entry] { monthEntries.filter { $0.type == .earning } }

    private var totalSpend:  Double { monthExpenses.map(\.amount).reduce(0, +) }
    private var totalIncome: Double { monthEarnings.map(\.amount).reduce(0, +) }
    private var netBalance:  Double { totalIncome - totalSpend }

    private var daysInMonth: Int {
        var c = DateComponents(); c.year = selectedYear; c.month = selectedMonth
        guard let d = cal.date(from: c) else { return 30 }
        return cal.range(of: .day, in: .month, for: d)?.count ?? 30
    }
    private var dailyAvg: Double { daysInMonth > 0 ? totalSpend / Double(daysInMonth) : 0 }

    private var biggestExpense: Entry? { monthExpenses.max(by: { $0.amount < $1.amount }) }

    private var busiestDay: (day: Int, amount: Double)? {
        var dict: [Int: Double] = [:]
        for e in monthExpenses { dict[cal.component(.day, from: e.date), default: 0] += e.amount }
        guard let max = dict.max(by: { $0.value < $1.value }) else { return nil }
        return (max.key, max.value)
    }

    private var iconBreakdown: [(icon: IconType, label: String, amount: Double, pct: Double)] {
        let total = totalSpend; guard total > 0 else { return [] }
        var dict: [IconType: Double] = [:]
        for e in monthExpenses { dict[e.icon, default: 0] += e.amount }
        return dict.map { (icon: $0.key, label: $0.key.label, amount: $0.value, pct: $0.value / total) }
                   .sorted { $0.amount > $1.amount }
    }

    private var monthlySpend: [Double] {
        (1...12).map { m in
            filtered.filter {
                $0.type == .expense &&
                cal.component(.year,  from: $0.date) == selectedYear &&
                cal.component(.month, from: $0.date) == m
            }.map(\.amount).reduce(0, +)
        }
    }
    private var monthlyIncome: [Double] {
        (1...12).map { m in
            filtered.filter {
                $0.type == .earning &&
                cal.component(.year,  from: $0.date) == selectedYear &&
                cal.component(.month, from: $0.date) == m
            }.map(\.amount).reduce(0, +)
        }
    }
    private var barMax: Double { max(monthlySpend.max() ?? 1, monthlyIncome.max() ?? 1, 1) }

    private var availableYears: [Int] {
        let s = Set(ledgerStore.entries.map { cal.component(.year, from: $0.date) })
        let cur = cal.component(.year, from: Date())
        return (s.isEmpty ? [cur] : Array(s).sorted()).filter { $0 <= cur }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerArea
                    ledgerSelector
                    monthOverviewCard
                    insightRow
                    barChartCard
                    yearSummaryCard       // ← 新增年度总结
                    pieChartCard
                    Spacer().frame(height: 100)
                }
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
    }

    // MARK: - Year Summary data

    private var yearTotalSpend:  Double { monthlySpend.reduce(0, +) }
    private var yearTotalIncome: Double { monthlyIncome.reduce(0, +) }
    private var yearNet:         Double { yearTotalIncome - yearTotalSpend }

    // 有数据的月份
    private var activeMonthsSpend:  [Double] { monthlySpend.filter  { $0 > 0 } }
    private var activeMonthsIncome: [Double] { monthlyIncome.filter { $0 > 0 } }

    private var avgMonthlySpend:  Double { activeMonthsSpend.isEmpty  ? 0 : yearTotalSpend  / Double(activeMonthsSpend.count) }
    private var avgMonthlyIncome: Double { activeMonthsIncome.isEmpty ? 0 : yearTotalIncome / Double(activeMonthsIncome.count) }

    private var peakSpendMonth:   (month: Int, amount: Double)? {
        let indexed = monthlySpend.enumerated().filter { $0.element > 0 }
        guard let max = indexed.max(by: { $0.element < $1.element }) else { return nil }
        return (max.offset + 1, max.element)
    }
    private var lowestSpendMonth: (month: Int, amount: Double)? {
        let indexed = monthlySpend.enumerated().filter { $0.element > 0 }
        guard let min = indexed.min(by: { $0.element < $1.element }) else { return nil }
        return (min.offset + 1, min.element)
    }
    private var spendRatio: Double {
        let total = yearTotalSpend + yearTotalIncome
        return total > 0 ? yearTotalSpend / total : 0
    }
    private var incomeRatio: Double { 1 - spendRatio }

    // MARK: - Year Summary Card

    private var yearSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            // 标题
            HStack {
                Text("\(selectedYear) \(t("year_summary"))")
                    .font(.system(size: 17, weight: .bold)).foregroundColor(textColor)
                Spacer()
            }

            // 总收支行
            HStack(spacing: 0) {
                yearStatBlock(title: t("year_total_income"), value: formatMoney(yearTotalIncome), color: incomeColor)
                Divider().frame(height: 40).opacity(0.15)
                yearStatBlock(title: t("year_total_spend"),  value: formatMoney(yearTotalSpend),  color: expenseColor)
                Divider().frame(height: 40).opacity(0.15)
                yearStatBlock(
                    title: t("year_net"),
                    value: (yearNet >= 0 ? "+" : "") + formatMoney(yearNet),
                    color: yearNet >= 0 ? incomeColor : expenseColor
                )
            }
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 14).fill(isDark ? Color(hex: "3A3A3C") : Color(hex: "F7F5FF")))

            // 收支占比条
            if yearTotalSpend + yearTotalIncome > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text(t("income_spend_ratio"))
                        .font(.system(size: 12)).foregroundColor(subColor)
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(incomeColor)
                                .frame(width: max(4, geo.size.width * CGFloat(incomeRatio)))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(expenseColor)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 12)
                    }
                    .frame(height: 12)
                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(incomeColor).frame(width: 8, height: 8)
                            Text(t("earning") + " \(Int(incomeRatio * 100))%")
                                .font(.system(size: 11)).foregroundColor(subColor)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(expenseColor).frame(width: 8, height: 8)
                            Text(t("spend") + " \(Int(spendRatio * 100))%")
                                .font(.system(size: 11)).foregroundColor(subColor)
                        }
                    }
                }
            }

            Divider().opacity(0.10)

            // 月均 + 峰值/最低月
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                yearInsightCell(
                    icon: "chart.bar.fill",
                    iconColor: accent,
                    title: t("avg_monthly_spend"),
                    value: formatMoney(avgMonthlySpend)
                )
                yearInsightCell(
                    icon: "arrow.up.circle.fill",
                    iconColor: incomeColor,
                    title: t("avg_monthly_income"),
                    value: formatMoney(avgMonthlyIncome)
                )
                if let peak = peakSpendMonth {
                    yearInsightCell(
                        icon: "flame.fill",
                        iconColor: expenseColor,
                        title: t("peak_spend_month"),
                        value: monthLabels[peak.month - 1],
                        sub: formatMoney(peak.amount)
                    )
                }
                if let low = lowestSpendMonth {
                    yearInsightCell(
                        icon: "leaf.fill",
                        iconColor: Color(hex: "34C759"),
                        title: t("lowest_spend_month"),
                        value: monthLabels[low.month - 1],
                        sub: formatMoney(low.amount)
                    )
                }
            }

            // 月度趋势迷你折线
            if activeMonthsSpend.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text(t("monthly_trend"))
                        .font(.system(size: 12)).foregroundColor(subColor)
                    GeometryReader { geo in
                        let maxVal = monthlySpend.max() ?? 1
                        let points: [CGPoint] = monthlySpend.enumerated().map { i, v in
                            CGPoint(
                                x: geo.size.width * CGFloat(i) / 11,
                                y: geo.size.height * (1 - CGFloat(v) / CGFloat(max(maxVal, 1)))
                            )
                        }
                        ZStack {
                            // 填充区域
                            Path { path in
                                guard points.count > 1 else { return }
                                path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                                path.addLine(to: points[0])
                                for p in points.dropFirst() { path.addLine(to: p) }
                                path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                                path.closeSubpath()
                            }
                            .fill(expenseColor.opacity(0.12))

                            // 折线
                            Path { path in
                                guard points.count > 1 else { return }
                                path.move(to: points[0])
                                for p in points.dropFirst() { path.addLine(to: p) }
                            }
                            .stroke(expenseColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                            // 月份标签
                            ForEach(Array(points.enumerated()), id: \.offset) { i, pt in
                                if i % 3 == 0 {
                                    Text(monthLabels[i])
                                        .font(.system(size: 8))
                                        .foregroundColor(subColor)
                                        .position(x: pt.x, y: geo.size.height + 8)
                                }
                            }
                        }
                    }
                    .frame(height: 60)
                    .padding(.bottom, 14)   // 给月份标签留空间
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(card))
        .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
    }

    private func yearStatBlock(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 10)).foregroundColor(subColor).multilineTextAlignment(.center)
            Text(value)
                .font(.system(size: 14, weight: .bold)).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }

    private func yearInsightCell(icon: String, iconColor: Color, title: String, value: String, sub: String? = nil) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(iconColor.opacity(0.12)).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 10)).foregroundColor(subColor).lineLimit(1)
                Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(textColor).lineLimit(1)
                if let s = sub {
                    Text(s).font(.system(size: 10)).foregroundColor(subColor).lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(isDark ? Color(hex: "3A3A3C") : Color(hex: "F7F5FF")))
    }

    // MARK: - Header

    private var headerArea: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(t("analytics_title"))
                    .font(.system(size: 32, weight: .heavy)).foregroundColor(textColor)
                Text(t("analytics_sub"))
                    .font(.system(size: 14)).foregroundColor(subColor)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 18)
    }

    // MARK: - Ledger Selector

    private var ledgerSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(label: t("filter_all_chip"), icon: "square.grid.2x2", isSelected: selectedLedgerID == nil) {
                    selectedLedgerID = nil
                }
                ForEach(ledgerStore.ledgers.filter { !$0.isTotal }) { l in
                    chipButton(label: l.name, emoji: l.emoji, isSelected: selectedLedgerID == l.id) {
                        selectedLedgerID = l.id
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chipButton(label: String, icon: String? = nil, emoji: String? = nil,
                             isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let ic = icon {
                    Image(systemName: ic).font(.system(size: 12))
                }
                if let em = emoji {
                    // SF Symbol name vs custom emoji
                    if em.hasPrefix("custom:") {
                        Text(String(em.dropFirst(7))).font(.system(size: 13))
                    } else if !em.isEmpty {
                        Image(systemName: em).font(.system(size: 12))
                    }
                }
                Text(label).font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : subColor)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(isSelected ? accent : card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Month Overview Card

    private var monthOverviewCard: some View {
        VStack(spacing: 14) {
            // Month nav
            HStack {
                Button { stepMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                }
                Spacer()
                Text("\(monthLabels[selectedMonth-1]) " + String(selectedYear))
                    .font(.system(size: 17, weight: .bold)).foregroundColor(textColor)
                Spacer()
                Button { stepMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                }
            }
            .padding(.horizontal, 4)

            Divider().opacity(0.10)

            HStack(spacing: 0) {
                statBlock(title: t("spend"),  value: formatMoney(totalSpend),  color: expenseColor)
                Divider().frame(height: 40).opacity(0.15)
                statBlock(title: t("earning"), value: formatMoney(totalIncome), color: incomeColor)
                Divider().frame(height: 40).opacity(0.15)
                statBlock(
                    title: t("net"),
                    value: (netBalance >= 0 ? "+" : "") + formatMoney(netBalance),
                    color: netBalance >= 0 ? incomeColor : expenseColor
                )
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(card))
        .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
    }

    private func stepMonth(_ delta: Int) {
        var m = selectedMonth + delta
        var y = selectedYear
        if m < 1  { m = 12; y -= 1 }
        if m > 12 { m = 1;  y += 1 }
        let cur = Date()
        let cy = cal.component(.year, from: cur), cm = cal.component(.month, from: cur)
        if y > cy || (y == cy && m > cm) { return }
        selectedMonth = m; selectedYear = y
    }

    private func statBlock(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 11)).foregroundColor(subColor)
            Text(value)
                .font(.system(size: 16, weight: .bold)).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Insight Row

    private var insightRow: some View {
        HStack(spacing: 12) {
            insightCard(
                icon: "calendar.badge.clock",
                iconColor: accent,
                title: t("daily_avg"),
                value: formatMoney(dailyAvg)
            )
            insightCard(
                icon: biggestExpense?.icon.symbol ?? "cart",
                iconColor: expenseColor,
                title: t("biggest_expense"),
                value: biggestExpense != nil ? formatMoney(biggestExpense!.amount) : "—",
                sub: biggestExpense?.category
            )
            insightCard(
                icon: "flame.fill",
                iconColor: Color(hex: "FF9500"),
                title: t("busiest_day"),
                value: busiestDay != nil ? t("day_prefix") + " \(busiestDay!.day)" : "—",
                sub: busiestDay != nil ? shortMoney(busiestDay!.amount) : nil
            )
        }
        .padding(.horizontal, 20)
    }

    private func insightCard(icon: String, iconColor: Color,
                              title: String, value: String, sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 10)).foregroundColor(subColor).lineLimit(1)
                Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(textColor)
                    .lineLimit(1).minimumScaleFactor(0.7)
                if let s = sub {
                    Text(s).font(.system(size: 10)).foregroundColor(subColor).lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(card))
        .shadow(color: .black.opacity(isDark ? 0.25 : 0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Bar Chart Card

    private var barChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(t("monthly_spending"))
                    .font(.system(size: 17, weight: .bold)).foregroundColor(textColor)
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        if let idx = availableYears.firstIndex(of: selectedYear), idx > 0 {
                            selectedYear = availableYears[idx - 1]
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(accent)
                            .frame(width: 26, height: 26)
                    }
                    Text(String(selectedYear))
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(textColor)
                        .frame(width: 44)
                    Button {
                        if let idx = availableYears.firstIndex(of: selectedYear),
                           idx < availableYears.count - 1 {
                            selectedYear = availableYears[idx + 1]
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(accent)
                            .frame(width: 26, height: 26)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 9).fill(card2))
            }

            HStack(spacing: 14) {
                legendDot(color: expenseColor, label: t("spend"))
                legendDot(color: incomeColor,  label: t("earning"))
                Spacer()
                let ys = monthlySpend.reduce(0, +)
                if ys > 0 {
                    Text("\(t("spend")): \(formatMoney(ys))")
                        .font(.system(size: 11)).foregroundColor(subColor)
                }
            }

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<12, id: \.self) { i in
                    let sp = monthlySpend[i], ic = monthlyIncome[i]
                    let sh = barMax > 0 ? max(sp  > 0 ? 4 : 0, CGFloat(sp  / barMax) * 130) : 0
                    let ih = barMax > 0 ? max(ic > 0 ? 4 : 0, CGFloat(ic / barMax) * 130) : 0
                    let sel = i + 1 == selectedMonth
                    VStack(spacing: 3) {
                        HStack(alignment: .bottom, spacing: 2) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(sel ? expenseColor : expenseColor.opacity(0.35))
                                .frame(width: 7, height: sh)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(sel ? incomeColor : incomeColor.opacity(0.35))
                                .frame(width: 7, height: ih)
                        }
                        Text(monthLabels[i])
                            .font(.system(size: 8, weight: sel ? .bold : .regular))
                            .foregroundColor(sel ? accent : subColor)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture { withAnimation(.spring(response: 0.3)) { selectedMonth = i + 1 } }
                }
            }
            .frame(height: 160)

            Text(t("tap_bar_hint") + " · " + monthLabels[selectedMonth-1])
                .font(.system(size: 11)).foregroundColor(subColor)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(card))
        .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundColor(subColor)
        }
    }

    // MARK: - Pie Chart Card

    private var pieChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(monthLabels[selectedMonth-1] + " " + String(selectedYear) + " " + t("breakdown_title"))
                .font(.system(size: 17, weight: .bold)).foregroundColor(textColor)

            if iconBreakdown.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40)).foregroundColor(subColor.opacity(0.30))
                    Text(t("no_spending_data"))
                        .font(.system(size: 14)).foregroundColor(subColor)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 36)
            } else {
                // Top-3 quick pills
                if iconBreakdown.count >= 2 {
                    HStack(spacing: 8) {
                        ForEach(Array(iconBreakdown.prefix(3).enumerated()), id: \.offset) { i, item in
                            HStack(spacing: 5) {
                                Image(systemName: item.icon.symbol).font(.system(size: 11))
                                Text("\(Int(item.pct * 100))%")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(pieColors[i % pieColors.count])
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(pieColors[i % pieColors.count].opacity(0.12)))
                        }
                        Spacer()
                    }
                }

                // Donut + legend
                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        PieChartView(
                            slices: iconBreakdown.enumerated().map { i, item in
                                PieSlice(value: item.pct, color: pieColors[i % pieColors.count])
                            }
                        )
                        .frame(width: 120, height: 120)
                        VStack(spacing: 1) {
                            let net = totalIncome - totalSpend
                            Text((net >= 0 ? "+" : "") + shortMoney(net))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(net >= 0 ? Color(hex: "34C759") : Color(hex: "FF6B6B"))
                            Text(t("net")).font(.system(size: 9)).foregroundColor(subColor)
                        }
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(iconBreakdown.prefix(5).enumerated()), id: \.offset) { i, item in
                            HStack(spacing: 7) {
                                Circle().fill(pieColors[i % pieColors.count]).frame(width: 9, height: 9)
                                Image(systemName: item.icon.symbol)
                                    .font(.system(size: 11)).foregroundColor(subColor).frame(width: 13)
                                Text(item.label)
                                    .font(.system(size: 12, weight: .medium)).foregroundColor(textColor)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(item.pct * 100))%")
                                    .font(.system(size: 11, weight: .semibold)).foregroundColor(subColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Divider().opacity(0.10).padding(.vertical, 4)

                // Full ranked list
                VStack(spacing: 0) {
                    ForEach(Array(iconBreakdown.enumerated()), id: \.offset) { i, item in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(pieColors[i % pieColors.count].opacity(0.13))
                                    .frame(width: 36, height: 36)
                                Image(systemName: item.icon.symbol)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(pieColors[i % pieColors.count])
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.label)
                                        .font(.system(size: 13, weight: .semibold)).foregroundColor(textColor)
                                    Spacer()
                                    Text(formatMoney(item.amount))
                                        .font(.system(size: 13, weight: .bold)).foregroundColor(textColor)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(pieColors[i % pieColors.count].opacity(0.15))
                                            .frame(height: 5)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(pieColors[i % pieColors.count])
                                            .frame(width: geo.size.width * CGFloat(item.pct), height: 5)
                                    }
                                }
                                .frame(height: 5)
                            }
                        }
                        .padding(.vertical, 9)
                        if i < iconBreakdown.count - 1 { Divider().opacity(0.07) }
                    }
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(card))
        .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func formatMoney(_ v: Double) -> String {
        let abs_v = abs(v)
        let sign = v < 0 ? "-" : ""
        if abs_v >= 1_000_000 {
            let m = abs_v / 1_000_000
            let s = String(format: "%.3f", m)
                .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
            return "\(sign)$\(s)M"
        } else if abs_v >= 1_000 {
            let k = abs_v / 1_000
            let s = String(format: "%.3f", k)
                .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
            return "\(sign)$\(s)k"
        }
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"
        f.maximumFractionDigits = 2; f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
    private func shortMoney(_ v: Double) -> String { formatMoney(v) }
}

// MARK: - Pie Chart

struct PieSlice { var value: Double; var color: Color }

struct PieChartView: View {
    var slices: [PieSlice]
    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(Array(cumulativeSlices().enumerated()), id: \.offset) { i, cs in
                    PieSliceShape(startAngle: cs.start, endAngle: cs.end).fill(slices[i].color)
                    PieSliceShape(startAngle: cs.start, endAngle: cs.end)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1.5)
                }
                Circle().fill(Color.clear)
                    .frame(width: size * 0.52, height: size * 0.52)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .frame(width: size, height: size)
            .position(center)
        }
    }
    private func cumulativeSlices() -> [(start: Angle, end: Angle)] {
        var r: [(Angle, Angle)] = []; var cur = -90.0
        for s in slices { let d = s.value * 360; r.append((.degrees(cur), .degrees(cur+d))); cur += d }
        return r
    }
}

struct PieSliceShape: Shape {
    var startAngle: Angle; var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY); let r = min(rect.width, rect.height) / 2
        var p = Path(); p.move(to: c)
        p.addArc(center: c, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.closeSubpath(); return p
    }
}
