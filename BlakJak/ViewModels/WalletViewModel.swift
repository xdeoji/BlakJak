import Foundation

@MainActor
class WalletViewModel: ObservableObject {
    @Published var balance: Int
    @Published var betAmount: Int = 50
    @Published var isInGame: Bool = false

    init() {
        self.balance = WalletStore.balance
    }

    var isBroke: Bool { balance < 10 }

    func deduct(_ amount: Int) {
        balance -= amount
        WalletStore.balance = balance
    }

    func credit(_ amount: Int) {
        balance += amount
        WalletStore.balance = balance
    }

    func canAfford(_ amount: Int) -> Bool {
        balance >= amount
    }
}
