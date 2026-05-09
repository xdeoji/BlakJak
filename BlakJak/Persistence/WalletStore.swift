import Foundation

struct WalletStore {
    /// Single key — balance and checksum are written together as one dictionary,
    /// making the write atomic. A crash mid-write can only corrupt this one key,
    /// which iOS will leave as either the old value or nil (never half-written).
    private static let walletKey      = "blakjak_wallet_v2"
    private static let hasLaunchedKey = "blakjak_has_launched"

    static var balance: Int {
        get {
            if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
                UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                write(1000)
                return 1000
            }

            guard let dict = UserDefaults.standard.dictionary(forKey: walletKey),
                  let stored = dict["balance"] as? Int,
                  let storedCK = dict["checksum"] as? String else {
                // Key missing entirely (fresh install or migration from old key) — not tampering
                return 0
            }

            if storedCK != IntegrityMonitor.checksum(for: stored) {
                // Checksum mismatch — flag for analytics review but trust the stored value.
                // We deliberately do NOT reset here: the false-positive risk (reinstall,
                // device restore, edge-case nil vendor ID) is too high and would erase
                // legitimately purchased chips.
                IntegrityMonitor.flagTamper(.balanceChecksum)
            }

            return stored
        }
        set { write(newValue) }
    }

    private static func write(_ value: Int) {
        let dict: [String: Any] = [
            "balance":  value,
            "checksum": IntegrityMonitor.checksum(for: value)
        ]
        UserDefaults.standard.set(dict, forKey: walletKey)
    }
}
