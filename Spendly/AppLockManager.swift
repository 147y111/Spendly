import SwiftUI
import CryptoKit

final class AppLockManager {
    static let shared = AppLockManager()
    private init() {}

    // MARK: - Per-account keys
    private func pinKey(_ phone: String)     -> String { "spendly_applock_pin_\(phone)" }
    private func enabledKey(_ phone: String) -> String { "spendly_applock_on_\(phone)" }

    // MARK: - Public API

    func isEnabled(for phone: String) -> Bool {
        UserDefaults.standard.bool(forKey: enabledKey(phone))
    }

    func hasPin(for phone: String) -> Bool {
        UserDefaults.standard.string(forKey: pinKey(phone)) != nil
    }

    func verify(pin: String, for phone: String) -> Bool {
        guard let stored = UserDefaults.standard.string(forKey: pinKey(phone)) else { return false }
        let matches = stored.hasPrefix("sha256:")
            ? stored == pinDigest(pin)
            : stored == pin
        if matches && !stored.hasPrefix("sha256:") {
            UserDefaults.standard.set(pinDigest(pin), forKey: pinKey(phone))
        }
        return matches
    }

    func savePin(_ pin: String, for phone: String) {
        UserDefaults.standard.set(pinDigest(pin), forKey: pinKey(phone))
        UserDefaults.standard.set(true, forKey: enabledKey(phone))
    }

    func disable(for phone: String) {
        UserDefaults.standard.set(false, forKey: enabledKey(phone))
    }

    func removeCredentials(for phone: String) {
        UserDefaults.standard.removeObject(forKey: pinKey(phone))
        UserDefaults.standard.removeObject(forKey: enabledKey(phone))
    }

    // MARK: - Session unlock (in-memory, plain var)
    private(set) var isUnlocked: Bool = false

    static let didUnlockNotification = Notification.Name("AppLockDidUnlock")

    func unlock() {
        isUnlocked = true
        NotificationCenter.default.post(name: Self.didUnlockNotification, object: nil)
    }

    func lock() {
        isUnlocked = false
    }

    private func pinDigest(_ pin: String) -> String {
        let digest = SHA256.hash(data: Data(pin.utf8))
        return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    }
}
