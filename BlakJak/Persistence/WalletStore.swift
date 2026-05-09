import Foundation

struct WalletStore {
    // iCloud KV — primary, syncs across devices and survives reinstalls
    private static let iCloudKey        = "blakjak_balance"
    // Local fallback — used when iCloud is unavailable (not signed in)
    private static let localKey         = "blakjak_wallet_v2"
    private static let hasLaunchedKey   = "blakjak_has_launched"
    private static let migratedCloudKey = "blakjak_migrated_cloud"

    private static var iCloud: NSUbiquitousKeyValueStore { .default }

    static var balance: Int {
        get {
            // First launch — check iCloud in case user is restoring on a new device
            if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
                UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                let cloudBalance = Int(iCloud.longLong(forKey: iCloudKey))
                if cloudBalance > 0 { return cloudBalance }
                write(1000)
                return 1000
            }

            // One-time migration: copy existing local balance up to iCloud
            if !UserDefaults.standard.bool(forKey: migratedCloudKey) {
                migrateToCloud()
            }

            // iCloud is authoritative when available — Apple's servers are the integrity layer
            let cloudBalance = Int(iCloud.longLong(forKey: iCloudKey))
            if cloudBalance > 0 { return cloudBalance }

            // iCloud unavailable (not signed in) — fall back to local with checksum validation
            return validatedLocalBalance
        }
        set { write(newValue) }
    }

    /// Call from WalletViewModel when NSUbiquitousKeyValueStore.didChangeExternallyNotification fires.
    static func handleiCloudSync() -> Int {
        Int(iCloud.longLong(forKey: iCloudKey))
    }

    // MARK: - Private

    private static func write(_ value: Int) {
        iCloud.set(Int64(value), forKey: iCloudKey)
        iCloud.synchronize()
        writeLocal(value)
    }

    private static func writeLocal(_ value: Int) {
        let dict: [String: Any] = [
            "balance":  value,
            "checksum": IntegrityMonitor.checksum(for: value)
        ]
        UserDefaults.standard.set(dict, forKey: localKey)
    }

    private static var validatedLocalBalance: Int {
        guard let dict = UserDefaults.standard.dictionary(forKey: localKey),
              let val = dict["balance"] as? Int,
              let ck  = dict["checksum"] as? String else { return 0 }
        if ck != IntegrityMonitor.checksum(for: val) {
            IntegrityMonitor.flagTamper(.balanceChecksum)
        }
        return val
    }

    private static func migrateToCloud() {
        UserDefaults.standard.set(true, forKey: migratedCloudKey)
        guard iCloud.longLong(forKey: iCloudKey) == 0 else { return }
        let local = validatedLocalBalance
        if local > 0 {
            iCloud.set(Int64(local), forKey: iCloudKey)
            iCloud.synchronize()
        }
    }
}
