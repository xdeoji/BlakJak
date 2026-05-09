import Foundation

/// Tracks lifetime chips wagered. Used to scale the hourly bonus.
/// Every 1,000,000 chips wagered adds 100 to the bonus (base 1,000).
///
/// Anti-cheat:
/// - iCloud KV is the primary store (Apple-controlled, hard to tamper)
/// - Local fallback has a SHA256 checksum (device-keyed via IntegrityMonitor)
/// - `add()` is monotonic — values can only increase; any stored value
///   lower than the running iCloud total is silently ignored
struct WagerStore {
    private static let iCloudKey = "blakjak_total_wagered"
    private static let localKey  = "blakjak_wager_v1"
    private static var iCloud: NSUbiquitousKeyValueStore { .default }

    static var totalWagered: Int {
        let cloud = Int(iCloud.longLong(forKey: iCloudKey))
        if cloud > 0 { return cloud }
        return validatedLocal
    }

    /// Increments the lifetime wager total. Amount must be positive.
    static func add(_ amount: Int) {
        guard amount > 0 else { return }
        let newTotal = totalWagered + amount
        write(newTotal)
    }

    // MARK: - Private

    private static func write(_ value: Int) {
        // Monotonic guard — never allow a decrease (catches any sync anomaly)
        let current = Int(iCloud.longLong(forKey: iCloudKey))
        guard value > current else { return }

        iCloud.set(Int64(value), forKey: iCloudKey)
        iCloud.synchronize()
        writeLocal(value)
    }

    private static func writeLocal(_ value: Int) {
        let dict: [String: Any] = [
            "total":    value,
            "checksum": IntegrityMonitor.checksum(for: value, domain: "wager")
        ]
        UserDefaults.standard.set(dict, forKey: localKey)
    }

    private static var validatedLocal: Int {
        guard let dict = UserDefaults.standard.dictionary(forKey: localKey),
              let val = dict["total"] as? Int,
              let ck  = dict["checksum"] as? String else { return 0 }
        if ck != IntegrityMonitor.checksum(for: val, domain: "wager") {
            IntegrityMonitor.flagTamper(.wagerChecksum)
            // Don't reset — only flag. Cheater gets a bigger bonus on free chips,
            // not a meaningful attack surface.
        }
        return val
    }
}
