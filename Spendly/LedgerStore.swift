import UserNotifications
import SwiftUI
import Combine

struct Ledger: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var isTotal: Bool = false
    var isPinned: Bool = false   // true = 主账本（启动时默认显示）
}

final class LedgerStore: ObservableObject {
    @Published var ledgers: [Ledger] = []
    @Published var selectedIndex: Int = 0
    @Published var entries: [Entry] = []

    private let saveKey:     String
    private let selectedKey: String
    private let entriesKey:  String

    init(userStore: UserStore? = nil) {
        let phone = userStore?.phone ?? "guest"
        saveKey     = "spendly_ledgers_\(phone)"
        selectedKey = "spendly_selected_ledger_\(phone)"
        entriesKey  = "spendly_entries_\(phone)"

        load()
        if ledgers.isEmpty {
            var total = Ledger(name: "Total", emoji: "📊", isTotal: true)
            total.isPinned = true   // Total 是初始主账本
            ledgers = [total]
            saveLedgers()
        }
        // 启动时跳到主账本（isPinned = true）
        if let pinnedIdx = ledgers.firstIndex(where: { $0.isPinned }) {
            selectedIndex = pinnedIdx
        } else {
            selectedIndex = UserDefaults.standard.integer(forKey: selectedKey)
            if selectedIndex >= ledgers.count { selectedIndex = 0 }
        }
        loadEntries()
    }

    var current: Ledger { ledgers[max(0, min(selectedIndex, ledgers.count - 1))] }

    func select(index: Int) {
        selectedIndex = index
        UserDefaults.standard.set(index, forKey: selectedKey)
    }

    /// 把指定 index 设为主账本（isPinned）
    func setDefault(index: Int) {
        for i in ledgers.indices { ledgers[i].isPinned = false }
        ledgers[index].isPinned = true
        saveLedgers()
    }

    func addLedger(name: String, emoji: String) {
        let new = Ledger(name: name, emoji: emoji)
        ledgers.append(new)
        selectedIndex = ledgers.count - 1
        UserDefaults.standard.set(selectedIndex, forKey: selectedKey)
        saveLedgers()
    }

    func deleteLedger(at index: Int, deleteEntries: Bool = true) {
        guard index < ledgers.count else { return }
        let ledger = ledgers[index]
        guard !ledger.isTotal else { return }
        if deleteEntries {
            entries.removeAll { $0.ledgerID == ledger.id }
        } else {
            // 保留记录，但把 ledgerID 设为 nil（归入总账本）
            for i in entries.indices where entries[i].ledgerID == ledger.id {
                entries[i].ledgerID = nil
            }
        }
        ledgers.remove(at: index)
        if selectedIndex >= ledgers.count {
            selectedIndex = max(0, ledgers.count - 1)
        } else if selectedIndex > index {
            selectedIndex -= 1
        }
        UserDefaults.standard.set(selectedIndex, forKey: selectedKey)
        saveEntries()
        saveLedgers()
    }

    // MARK: - Entries

    private var deletedEntries: [Entry] = []

    func addEntry(_ entry: Entry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }

    func updateEntry(_ entry: Entry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
            entries.sort { $0.date > $1.date }
            saveEntries()
        }
    }

    func deleteEntry(_ entry: Entry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            deletedEntries.append(entries[idx])
            entries.remove(at: idx)
            saveEntries()
        }
    }

    func undoDelete() {
        guard let last = deletedEntries.popLast() else { return }
        entries.insert(last, at: 0)
        entries.sort { $0.date > $1.date }
        saveEntries()
    }

    func saveEntriesPublic() { saveEntries() }

    // MARK: - Recurring Auto-Entry
    func processRecurring() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var changed = false

        for entry in entries where entry.recurring != .none {
            guard let nextDue = entry.nextDueDate else { continue }
            let dueDay = cal.startOfDay(for: nextDue)
            guard dueDay <= today else { continue }

            // 创建新记录
            var newEntry = entry
            newEntry.id = UUID()
            newEntry.date = Date()
            newEntry.nextDueDate = nextDueDate(after: Date(), frequency: entry.recurring, customDays: entry.customIntervalDays)
            entries.insert(newEntry, at: 0)

            // 更新原记录的 nextDueDate
            if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[idx].nextDueDate = newEntry.nextDueDate
            }
            changed = true
            scheduleNotification(for: newEntry)
        }
        if changed { saveEntries() }
    }

    func nextDueDate(after date: Date, frequency: RecurringFrequency, customDays: Int) -> Date {
        let cal = Calendar.current
        switch frequency {
        case .none:      return date
        case .weekly:    return cal.date(byAdding: .weekOfYear, value: 1,  to: date) ?? date
        case .monthly:   return cal.date(byAdding: .month,      value: 1,  to: date) ?? date
        case .quarterly: return cal.date(byAdding: .month,      value: 3,  to: date) ?? date
        case .yearly:    return cal.date(byAdding: .year,        value: 1,  to: date) ?? date
        case .custom:
            let days = customDays > 0 ? customDays : 30
            return cal.date(byAdding: .day, value: days, to: date) ?? date
        }
    }

    func scheduleNotification(for entry: Entry) {
        guard let nextDue = entry.nextDueDate,
              let notifyDate = Calendar.current.date(byAdding: .day, value: -1, to: nextDue),
              notifyDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Spendly"
        content.body  = "Reminder: \(entry.category) (\(entry.recurring.label)) is due tomorrow"
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "recurring-\(entry.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Persistence

    func saveLedgers() {
        if let data = try? JSONEncoder().encode(ledgers) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Ledger].self, from: data)
        else { return }
        ledgers = decoded
        if ledgers.first?.isTotal != true {
            var total = Ledger(name: "Total", emoji: "📊", isTotal: true)
            total.isPinned = true
            ledgers.insert(total, at: 0)
            saveLedgers()
        }
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries.map { CodableEntry($0) }) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([CodableEntry].self, from: data)
        else { return }
        entries = decoded.map { $0.toEntry() }
    }
}

// MARK: - CodableEntry

struct CodableEntry: Codable {
    var id: UUID
    var date: Date
    var category: String
    var note: String
    var payMethod: String
    var amount: Double
    var isExpense: Bool
    var iconRaw: Int
    var ledgerID: UUID?
    var sizeLabelRaw: Int
    var recurringRaw: Int
    var noteImageData: Data?
    var nextDueDate: Date?
    var customIntervalDays: Int?
    var customUnitStr: String?
    var customUnitCount: Int?

    init(_ e: Entry) {
        id = e.id; date = e.date; category = e.category
        note = e.note; payMethod = e.payMethod; amount = e.amount
        isExpense = e.type == .expense
        iconRaw = e.icon.rawValue
        ledgerID = e.ledgerID
        sizeLabelRaw = e.sizeLabel.rawValue
        recurringRaw = e.recurring.rawValue
        noteImageData = e.noteImageData
        nextDueDate = e.nextDueDate
        customIntervalDays = e.customIntervalDays
        customUnitStr = e.customUnitStr
        customUnitCount = e.customUnitCount
    }

    func toEntry() -> Entry {
        var e = Entry(date: date, category: category, note: note, payMethod: payMethod,
                      amount: amount, type: isExpense ? .expense : .earning,
                      icon: IconType(rawValue: iconRaw) ?? .meal,
                      ledgerID: ledgerID,
                      sizeLabel: SizeLabel(rawValue: sizeLabelRaw) ?? .minor,
                      noteImageData: noteImageData,
                      recurring: RecurringFrequency(rawValue: recurringRaw) ?? .none,
                      nextDueDate: nextDueDate,
                      customIntervalDays: customIntervalDays ?? 30,
                      customUnitStr: customUnitStr ?? "days",
                      customUnitCount: customUnitCount ?? 1)
        e.id = id
        return e
    }
}
