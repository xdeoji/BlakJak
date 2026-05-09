import Foundation

struct WalletStore {
    private static let balanceKey    = "blakjak_balance"
    private static let checksumKey   = "blakjak_balance_ck"
    private static let hasLaunchedKey = "blakjak_has_launched"

    static var balance: Int {
        get {
            if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
                UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                write(1000)
                return 1000
            }

            let stored = UserDefaults.standard.integer(forKey: balanceKey)
            let storedCK = UserDefaults.standard.string(forKey: checksumKey) ?? ""

            if storedCK != IntegrityMonitor.checksum(for: stored) {
                // Stored balance was tampered — reset and flag
                IntegrityMonitor.flagTamper(.balanceChecksum)
                write(1000)
                return 1000
            }
            return stored
        }
        set { write(newValue) }
    }

    private static func write(_ value: Int) {
        UserDefaults.standard.set(value, forKey: balanceKey)
        UserDefaults.standard.set(IntegrityMonitor.checksum(for: value), forKey: checksumKey)
    }
}
