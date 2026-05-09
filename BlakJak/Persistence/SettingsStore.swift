import Foundation

struct SettingsStore {
    private static let riskyConfirmKey = "blakjak_risky_confirm"
    private static let lifetimeHandCountKey = "blakjak_lifetime_hand_count"

    private static let onboardedKey = "blakjak_onboarded"
    private static let customBetKey = "blakjak_custom_bet"

    static var hasOnboarded: Bool {
        get { UserDefaults.standard.bool(forKey: onboardedKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardedKey) }
    }

    static var customBetAmount: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: customBetKey)
            return val > 0 ? val : 50
        }
        set { UserDefaults.standard.set(newValue, forKey: customBetKey) }
    }

    /// Monotonically increasing count of all hands ever generated — used for lifetime hand IDs.
    static func incrementAndGetLifetimeHandCount() -> Int {
        let next = UserDefaults.standard.integer(forKey: lifetimeHandCountKey) + 1
        UserDefaults.standard.set(next, forKey: lifetimeHandCountKey)
        return next
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
