import Foundation

struct SettingsStore {
    private static let riskyConfirmKey = "blakjak_risky_confirm"

    private static let customBetKey = "blakjak_custom_bet"

    static var customBetAmount: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: customBetKey)
            return val > 0 ? val : 50
        }
        set { UserDefaults.standard.set(newValue, forKey: customBetKey) }
    }

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
