import Foundation

struct BankStore {
    private static let iCloudKey = "blakjak_bank_balance"
    private static var iCloud: NSUbiquitousKeyValueStore { .default }

    static var balance: Int {
        get {
            let cloud = Int(iCloud.longLong(forKey: iCloudKey))
            if cloud > 0 { return cloud }
            // Fall back to local (pre-iCloud users / iCloud unavailable)
            return UserDefaults.standard.integer(forKey: iCloudKey)
        }
        set {
            iCloud.set(Int64(newValue), forKey: iCloudKey)
            iCloud.synchronize()
            UserDefaults.standard.set(newValue, forKey: iCloudKey)
        }
    }
}
