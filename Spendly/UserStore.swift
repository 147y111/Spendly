import SwiftUI
import Combine

final class UserStore: ObservableObject {
    @Published var username: String
    @Published var phone: String
    @Published var email: String
    @Published var avatarData: Data?
    @Published var isLoggedIn: Bool = true

    // 当前账号的手机号，用于隔离数据
    private let accountPhone: String

    private var usernameKey: String { "spendly_username_\(accountPhone)" }
    private var emailKey:    String { "spendly_email_\(accountPhone)" }
    private var avatarKey:   String { "spendly_avatar_\(accountPhone)" }

    // Ledger keys 也按账号隔离
    var ledgersKey:      String { "spendly_ledgers_\(accountPhone)" }
    var selectedKey:     String { "spendly_selected_ledger_\(accountPhone)" }
    var entriesKey:      String { "spendly_entries_\(accountPhone)" }

    init(phone: String = "") {
        self.accountPhone = phone.isEmpty ? "guest" : phone
        username  = UserDefaults.standard.string(forKey: "spendly_username_\(accountPhone)") ?? "User name"
        self.phone = phone
        email     = UserDefaults.standard.string(forKey: "spendly_email_\(accountPhone)") ?? ""
        avatarData = UserDefaults.standard.data(forKey: "spendly_avatar_\(accountPhone)")
    }

    func saveUsername(_ value: String) {
        username = value
        UserDefaults.standard.set(value, forKey: usernameKey)
    }

    func savePhone(_ value: String) {
        phone = value
    }

    func saveEmail(_ value: String) {
        email = value
        UserDefaults.standard.set(value, forKey: emailKey)
    }

    func saveAvatar(_ image: UIImage) {
        let data = image.jpegData(compressionQuality: 0.8)
        avatarData = data
        UserDefaults.standard.set(data, forKey: avatarKey)
    }

    var avatarImage: UIImage? {
        guard let data = avatarData else { return nil }
        return UIImage(data: data)
    }

    func signOut() {
        AuthManager.shared.logout()
        isLoggedIn = false
    }

    func deleteAccount() {
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: avatarKey)
        UserDefaults.standard.removeObject(forKey: ledgersKey)
        UserDefaults.standard.removeObject(forKey: selectedKey)
        UserDefaults.standard.removeObject(forKey: entriesKey)
        AppLockManager.shared.removeCredentials(for: accountPhone)
        AuthManager.shared.deleteUser(phone: accountPhone)
        isLoggedIn = false
    }
}
