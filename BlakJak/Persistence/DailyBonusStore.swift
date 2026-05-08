import Foundation

struct DailyBonusStore {
    private static let lastClaimKey = "blakjak_daily_bonus_last_claim"
    static let bonusAmount = 250

    static var lastClaimed: Date? {
        get { UserDefaults.standard.object(forKey: lastClaimKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastClaimKey) }
    }

    static var isAvailable: Bool {
        guard let last = lastClaimed else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    static func claim() {
        lastClaimed = Date()
    }
}
