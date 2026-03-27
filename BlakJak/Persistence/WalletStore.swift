import Foundation

struct WalletStore {
    private static let balanceKey = "blakjak_balance"
    private static let hasLaunchedKey = "blakjak_has_launched"

    static var balance: Int {
        get {
            if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
                UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                UserDefaults.standard.set(1000, forKey: balanceKey)
                return 1000
            }
            return UserDefaults.standard.integer(forKey: balanceKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: balanceKey)
        }
    }
}
