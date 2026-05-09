import Foundation

struct HandRecord: Codable {
    let betAmount: Int
    let multiplier: Double
    let payout: Int
    let wasWin: Bool
    let wasPush: Bool
    let timestamp: Date
}

/// Stores hand history in iCloud KV, capped at 500 records to stay within the 1MB per-key limit.
/// Falls back to UserDefaults if iCloud is unavailable.
struct StatsStore {
    private static let iCloudKey = "blakjak_hand_records_v2"
    private static let localKey  = "blakjak_hand_records"
    private static let maxRecords = 500
    private static var iCloud: NSUbiquitousKeyValueStore { .default }

    static var records: [HandRecord] {
        get {
            // Try iCloud first
            if let data = iCloud.data(forKey: iCloudKey),
               let decoded = try? JSONDecoder().decode([HandRecord].self, from: data) {
                return decoded
            }
            // Fall back to local
            if let data = UserDefaults.standard.data(forKey: localKey),
               let decoded = try? JSONDecoder().decode([HandRecord].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            // Cap to avoid exceeding iCloud KV limits
            let capped = Array(newValue.suffix(maxRecords))
            if let encoded = try? JSONEncoder().encode(capped) {
                iCloud.set(encoded, forKey: iCloudKey)
                iCloud.synchronize()
                UserDefaults.standard.set(encoded, forKey: localKey)
            }
        }
    }

    static func record(_ hand: HandRecord) {
        var current = records
        current.append(hand)
        records = current
    }
}
