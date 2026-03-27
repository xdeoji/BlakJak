import Foundation

struct StreakStore {
    private static let winStreakKey = "blakjak_win_streak"
    private static let lossStreakKey = "blakjak_loss_streak"
    private static let streaksEnabledKey = "blakjak_streaks_enabled"

    static var winStreak: Int {
        get { UserDefaults.standard.integer(forKey: winStreakKey) }
        set { UserDefaults.standard.set(newValue, forKey: winStreakKey) }
    }

    static var lossStreak: Int {
        get { UserDefaults.standard.integer(forKey: lossStreakKey) }
        set { UserDefaults.standard.set(newValue, forKey: lossStreakKey) }
    }

    static var streaksEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: streaksEnabledKey) == nil {
                return true // default on
            }
            return UserDefaults.standard.bool(forKey: streaksEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: streaksEnabledKey) }
    }
}
