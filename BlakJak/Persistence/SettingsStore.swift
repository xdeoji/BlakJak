import Foundation

struct SettingsStore {
    private static let riskyConfirmKey = "blakjak_risky_confirm"

    /// Confirm before hitting/doubling on 17+
    static var riskyActionConfirm: Bool {
        get {
            if UserDefaults.standard.object(forKey: riskyConfirmKey) == nil {
                return true // default on
            }
            return UserDefaults.standard.bool(forKey: riskyConfirmKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: riskyConfirmKey) }
    }
}
