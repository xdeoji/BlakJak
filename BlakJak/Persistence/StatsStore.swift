import Foundation

struct HandRecord: Codable {
    let betAmount: Int
    let multiplier: Double
    let payout: Int
    let wasWin: Bool
    let wasPush: Bool
    let timestamp: Date
}

struct StatsStore {
    private static let key = "blakjak_hand_records"

    static var records: [HandRecord] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([HandRecord].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }

    static func record(_ hand: HandRecord) {
        var current = records
        current.append(hand)
        records = current
    }
}
