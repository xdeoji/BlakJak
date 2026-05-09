import Foundation

struct BankStore {
    private static let balanceKey = "blakjak_bank_balance"

    static var balance: Int {
        get { UserDefaults.standard.integer(forKey: balanceKey) }
        set { UserDefaults.standard.set(newValue, forKey: balanceKey) }
    }
}
