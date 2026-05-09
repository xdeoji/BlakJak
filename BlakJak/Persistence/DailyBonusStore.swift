import Foundation

struct DailyBonusStore {
    private static let lastClaimKey = "blakjak_daily_bonus_last_claim"
    /// Base 1,000 + 100 per 1,000,000 chips wagered lifetime.
    static var bonusAmount: Int {
        1000 + (WagerStore.totalWagered / 1_000_000) * 100
    }

    static var lastClaimed: Date? {
        get { UserDefaults.standard.object(forKey: lastClaimKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastClaimKey) }
    }

    static var isAvailable: Bool {
        guard let last = lastClaimed else { return false }
        return Date().timeIntervalSince(last) >= 3600
    }

    static var timeUntilAvailable: TimeInterval {
        guard let last = lastClaimed else { return 0 }
        return max(0, 3600 - Date().timeIntervalSince(last))
    }

    static func claim() {
        lastClaimed = Date()
    }
}
