import Foundation

@MainActor
class WalletViewModel: ObservableObject {
    @Published var balance: Int
    @Published var betAmount: Int = 50
    @Published var isInGame: Bool = false

    init() {
        self.balance = WalletStore.balance
    }

    private let topUpThreshold = 10
    private let topUpAmount = 1000

    func deduct(_ amount: Int) {
        balance -= amount
        WalletStore.balance = balance
        checkTopUp()
    }

    func credit(_ amount: Int) {
        balance += amount
        WalletStore.balance = balance
        checkTopUp()
    }

    func canAfford(_ amount: Int) -> Bool {
        balance >= amount
    }

    private func checkTopUp() {
        if balance < topUpThreshold {
            balance = topUpAmount
            WalletStore.balance = balance
        }
    }
}
