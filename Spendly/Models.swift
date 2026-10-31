import SwiftUI
import Foundation
import Combine

// ================================================
// Entry & EntryType & IconType
// ================================================

enum EntryType { case earning, expense }
enum SizeLabel: Int, Codable { case minor = 0, moderate = 1, major = 2 }

// 习惯性支出/收入的重复频率
enum RecurringFrequency: Int, Codable, CaseIterable {
    case none      = 0
    case weekly    = 1
    case monthly   = 2
    case quarterly = 3
    case yearly    = 4
    case custom    = 5

    var label: String {
        switch self {
        case .none:      return t("one_time")
        case .weekly:    return t("weekly")
        case .monthly:   return t("monthly")
        case .quarterly: return t("quarterly")
        case .yearly:    return t("yearly")
        case .custom:    return t("custom_interval")
        }
    }
    var icon: String {
        switch self {
        case .none:      return "1.circle"
        case .weekly:    return "7.circle"
        case .monthly:   return "calendar"
        case .quarterly: return "calendar.badge.clock"
        case .yearly:    return "star.circle"
        case .custom:    return "slider.horizontal.3"
        }
    }
}

enum IconType: Int, Codable, CaseIterable {
    case meal      = 0
    case car       = 1
    case earning   = 2
    case home      = 3
    case medical   = 4
    case shopping  = 5
    case education = 6
    case travel    = 7
    case pet       = 8
    case entertainment = 9
    case fitness   = 10
    case coffee    = 11

    var symbol: String {
        switch self {
        case .meal:          return "fork.knife"
        case .car:           return "car.fill"
        case .earning:       return "dollarsign.circle.fill"
        case .home:          return "house.fill"
        case .medical:       return "cross.fill"
        case .shopping:      return "cart.fill"
        case .education:     return "pencil"
        case .travel:        return "airplane"
        case .pet:           return "pawprint.fill"
        case .entertainment: return "tv.fill"
        case .fitness:       return "figure.run"
        case .coffee:        return "cup.and.saucer.fill"
        }
    }
    var label: String {
        switch self {
        case .meal:          return t("icon_meal")
        case .car:           return t("icon_car")
        case .earning:       return t("icon_income")
        case .home:          return t("icon_home")
        case .medical:       return t("icon_medical")
        case .shopping:      return t("icon_shopping")
        case .education:     return t("icon_study")
        case .travel:        return t("icon_travel")
        case .pet:           return t("icon_pet")
        case .entertainment: return t("icon_fun")
        case .fitness:       return t("icon_fitness")
        case .coffee:        return t("icon_cafe")
        }
    }
}

// 支付方式
enum PayMethod: String, Codable, CaseIterable {
    case cash       = "Cash"
    case creditCard = "Credit Card"
    case debitCard  = "Debit Card"
    case applePay   = "Apple Pay"
    case wechatPay  = "WeChat Pay"
    case alipay     = "Alipay"
    case bankTransfer = "Bank Transfer"
    case other      = "Other"

    var displayName: String {
        switch self {
        case .cash:         return t("pay_cash")
        case .creditCard:   return t("pay_credit_card")
        case .debitCard:    return t("pay_debit_card")
        case .applePay:     return t("pay_apple_pay")
        case .wechatPay:    return t("pay_wechat")
        case .alipay:       return t("pay_alipay")
        case .bankTransfer: return t("pay_bank_transfer")
        case .other:        return t("pay_other")
        }
    }
    var icon: String {
        switch self {
        case .cash:         return "dollarsign.circle"
        case .creditCard:   return "creditcard"
        case .debitCard:    return "creditcard.fill"
        case .applePay:     return "applelogo"
        case .wechatPay:    return "message.circle"
        case .alipay:       return "a.circle"
        case .bankTransfer: return "building.columns"
        case .other:        return "ellipsis.circle"
        }
    }
}

struct Entry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var category: String
    var note: String
    var payMethod: String
    var amount: Double
    var type: EntryType
    var icon: IconType
    var ledgerID: UUID?
    var sizeLabel: SizeLabel = .minor
    var noteImageData: Data? = nil
    var recurring: RecurringFrequency = .none   // 习惯性记录频率
    var nextDueDate: Date? = nil                // 下次到期日（nil = 未启用循环）
    var customIntervalDays: Int = 30            // 自定义间隔天数（已换算为天）
    var customUnitStr: String = "days"          // 原始单位：days/weeks/months/years
    var customUnitCount: Int = 1                // 原始数量

    enum CodingKeys: String, CodingKey {
        case id, date, category, note, payMethod, amount, isExpense, iconRaw, ledgerID, sizeLabelRaw, noteImageData, recurringRaw, nextDueDate, customIntervalDays, customUnitStr, customUnitCount
    }
    init(date: Date, category: String, note: String, payMethod: String,
         amount: Double, type: EntryType, icon: IconType, ledgerID: UUID? = nil,
         sizeLabel: SizeLabel = .minor, noteImageData: Data? = nil,
         recurring: RecurringFrequency = .none,
         nextDueDate: Date? = nil,
         customIntervalDays: Int = 30,
         customUnitStr: String = "days",
         customUnitCount: Int = 1) {
        self.date = date; self.category = category; self.note = note
        self.payMethod = payMethod; self.amount = amount
        self.type = type; self.icon = icon; self.ledgerID = ledgerID
        self.sizeLabel = sizeLabel; self.noteImageData = noteImageData
        self.recurring = recurring
        self.nextDueDate = nextDueDate
        self.customIntervalDays = customIntervalDays
        self.customUnitStr = customUnitStr
        self.customUnitCount = customUnitCount
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,   forKey: .id)
        date      = try c.decode(Date.self,   forKey: .date)
        category  = try c.decode(String.self, forKey: .category)
        note      = try c.decode(String.self, forKey: .note)
        payMethod = try c.decode(String.self, forKey: .payMethod)
        amount    = try c.decode(Double.self, forKey: .amount)
        ledgerID  = try c.decodeIfPresent(UUID.self, forKey: .ledgerID)
        let isExpense = try c.decode(Bool.self, forKey: .isExpense)
        type = isExpense ? .expense : .earning
        let iconRaw = (try? c.decodeIfPresent(Int.self, forKey: .iconRaw)) ?? 0
        icon = IconType(rawValue: iconRaw) ?? .meal
        let slRaw = (try? c.decodeIfPresent(Int.self, forKey: .sizeLabelRaw)) ?? nil
        sizeLabel = SizeLabel(rawValue: slRaw ?? 0) ?? .minor
        noteImageData = try? c.decodeIfPresent(Data.self, forKey: .noteImageData) ?? nil
        let recRaw = (try? c.decodeIfPresent(Int.self, forKey: .recurringRaw)) ?? nil
        recurring = RecurringFrequency(rawValue: recRaw ?? 0) ?? .none
        nextDueDate = try? c.decodeIfPresent(Date.self, forKey: .nextDueDate) ?? nil
        customIntervalDays = (try? c.decodeIfPresent(Int.self, forKey: .customIntervalDays)) ?? 30
        customUnitStr   = (try? c.decodeIfPresent(String.self, forKey: .customUnitStr))   ?? "days"
        customUnitCount = (try? c.decodeIfPresent(Int.self,    forKey: .customUnitCount)) ?? 1
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                  forKey: .id)
        try c.encode(date,                forKey: .date)
        try c.encode(category,            forKey: .category)
        try c.encode(note,                forKey: .note)
        try c.encode(payMethod,           forKey: .payMethod)
        try c.encode(amount,              forKey: .amount)
        try c.encode(ledgerID,            forKey: .ledgerID)
        try c.encode(type == .expense,    forKey: .isExpense)
        try c.encode(icon.rawValue,       forKey: .iconRaw)
        try c.encode(sizeLabel.rawValue,  forKey: .sizeLabelRaw)
        try c.encodeIfPresent(noteImageData, forKey: .noteImageData)
        try c.encode(recurring.rawValue,  forKey: .recurringRaw)
        try c.encodeIfPresent(nextDueDate,        forKey: .nextDueDate)
        try c.encode(customIntervalDays,           forKey: .customIntervalDays)
        try c.encode(customUnitStr,                    forKey: .customUnitStr)
        try c.encode(customUnitCount,                  forKey: .customUnitCount)
    }
}

// ================================================
// DashboardVM
// ================================================

final class DashboardVM: ObservableObject {
    @Published var selectedMonth: Date = Date()

    func filtered(entries: [Entry], for ledger: Ledger) -> [Entry] {
        let cal = Calendar.current
        let base = ledger.isTotal ? entries : entries.filter { $0.ledgerID == ledger.id }
        return base.filter { cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }
    func totalEarnings(entries: [Entry], for ledger: Ledger) -> Double {
        filtered(entries: entries, for: ledger).filter { $0.type == .earning }.map(\.amount).reduce(0, +)
    }
    func totalExpenses(entries: [Entry], for ledger: Ledger) -> Double {
        filtered(entries: entries, for: ledger).filter { $0.type == .expense }.map(\.amount).reduce(0, +)
    }
    func totalNet(entries: [Entry], for ledger: Ledger) -> Double {
        totalEarnings(entries: entries, for: ledger) - totalExpenses(entries: entries, for: ledger)
    }
    func groupedExpensesByDay(entries: [Entry], for ledger: Ledger) -> [(title: String, items: [Entry])] {
        let cal = Calendar.current
        let all = filtered(entries: entries, for: ledger).sorted { $0.date > $1.date }
        let groups = Dictionary(grouping: all) { cal.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in (dayTitle(day), (groups[day] ?? []).sorted { $0.date > $1.date }) }
    }
    func daysWithEntries(entries: [Entry], for ledger: Ledger) -> Set<String> {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        return Set(filtered(entries: entries, for: ledger).map { df.string(from: $0.date) })
    }
    func monthText() -> String {
        let df = DateFormatter(); df.dateFormat = "MM/yyyy"; return df.string(from: selectedMonth)
    }
    func dayTitle(_ date: Date) -> String {
        let cal = Calendar.current
        let year    = cal.component(.year,    from: date)
        let month   = cal.component(.month,   from: date)
        let day     = cal.component(.day,     from: date)
        let weekday = cal.component(.weekday, from: date)
        let weekdayKeys = ["weekday_sun","weekday_mon","weekday_tue","weekday_wed","weekday_thu","weekday_fri","weekday_sat"]
        let wdStr = t(weekdayKeys[weekday - 1])
        let currentYear = cal.component(.year, from: Date())
        if year == currentYear {
            return String(format: "%02d/%02d %@", month, day, wdStr)
        } else {
            return String(format: "%d/%02d/%02d %@", year, month, day, wdStr)
        }
    }
}
