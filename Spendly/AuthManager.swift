import Foundation
import Combine
import CryptoKit

struct SpendlyUser: Codable {
    var phone: String
    var password: String
    var name: String
}

final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isLoggedIn: Bool = false
    @Published var currentUser: SpendlyUser? = nil

    private let usersKey          = "spendly_users"
    private let loggedInPhoneKey  = "spendly_loggedin_phone"
    private let recentPhonesKey   = "spendly_recent_phones"

    private init() {
        if let phone = UserDefaults.standard.string(forKey: loggedInPhoneKey),
           let user = getUser(phone: phone) {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }

    // 在这台设备上登录过的所有账号（按最近登录排序）
    var recentAccounts: [SpendlyUser] {
        let phones = UserDefaults.standard.stringArray(forKey: recentPhonesKey) ?? []
        return phones.compactMap { getUser(phone: $0) }
    }

    func register(phone: String, password: String, name: String) -> String? {
        let p  = phone.trimmingCharacters(in: .whitespaces)
        let pw = password.trimmingCharacters(in: .whitespaces)
        let n  = name.trimmingCharacters(in: .whitespaces)

        guard p.count >= 8  else { return "Please enter a valid phone number" }
        guard pw.count >= 6 else { return "Password must be at least 6 characters" }
        guard !n.isEmpty    else { return "Please enter your name" }
        if getUser(phone: p) != nil { return "This phone number is already registered" }

        saveUser(SpendlyUser(phone: p, password: passwordDigest(pw), name: n))
        return nil
    }

    func login(phone: String, password: String) -> String? {
        let p  = phone.trimmingCharacters(in: .whitespaces)
        let pw = password.trimmingCharacters(in: .whitespaces)
        guard var user = getUser(phone: p) else { return "Phone number not registered" }
        guard passwordMatches(pw, stored: user.password) else { return "Incorrect password" }
        if !user.password.hasPrefix("sha256:") {
            user.password = passwordDigest(pw)
            saveUser(user)
        }

        currentUser = user
        isLoggedIn  = true
        UserDefaults.standard.set(p, forKey: loggedInPhoneKey)
        addToRecentPhones(p)
        return nil
    }

    func logout() {
        currentUser = nil
        isLoggedIn  = false
        UserDefaults.standard.removeObject(forKey: loggedInPhoneKey)
    }

    func deleteUser(phone: String) {
        let p = phone.trimmingCharacters(in: .whitespaces)
        var users: [String: SpendlyUser] = [:]
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let existing = try? JSONDecoder().decode([String: SpendlyUser].self, from: data) {
            users = existing
        }
        users.removeValue(forKey: p)
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
        var phones = UserDefaults.standard.stringArray(forKey: recentPhonesKey) ?? []
        phones.removeAll { $0 == p }
        UserDefaults.standard.set(phones, forKey: recentPhonesKey)
        logout()
    }

    // MARK: - Private

    private func addToRecentPhones(_ phone: String) {
        var phones = UserDefaults.standard.stringArray(forKey: recentPhonesKey) ?? []
        phones.removeAll { $0 == phone }
        phones.insert(phone, at: 0)   // 最近的排最前
        UserDefaults.standard.set(phones, forKey: recentPhonesKey)
    }

    func getUser(phone: String) -> SpendlyUser? {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([String: SpendlyUser].self, from: data)
        else { return nil }
        return users[phone]
    }

    /// 验证当前用户密码是否正确
    func verifyPassword(_ password: String, for phone: String) -> Bool {
        let pw = password.trimmingCharacters(in: .whitespaces)
        let p  = phone.trimmingCharacters(in: .whitespaces)
        guard var user = getUser(phone: p),
              passwordMatches(pw, stored: user.password) else { return false }
        if !user.password.hasPrefix("sha256:") {
            user.password = passwordDigest(pw)
            saveUser(user)
            if currentUser?.phone == p { currentUser = user }
        }
        return true
    }

    /// 修改密码并同步 currentUser
    func updatePassword(_ newPassword: String, for phone: String) {
        let pw = newPassword.trimmingCharacters(in: .whitespaces)
        let p  = phone.trimmingCharacters(in: .whitespaces)
        guard var user = getUser(phone: p) else { return }
        user.password = passwordDigest(pw)
        saveUser(user)
        if currentUser?.phone == p {
            currentUser = user
        }
    }

    private func saveUser(_ user: SpendlyUser) {
        var users: [String: SpendlyUser] = [:]
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let existing = try? JSONDecoder().decode([String: SpendlyUser].self, from: data) {
            users = existing
        }
        users[user.phone] = user
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    private func passwordDigest(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    }

    private func passwordMatches(_ candidate: String, stored: String) -> Bool {
        stored.hasPrefix("sha256:")
            ? stored == passwordDigest(candidate)
            : stored == candidate
    }
}
