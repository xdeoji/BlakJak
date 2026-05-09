import Foundation

@MainActor
class WalletViewModel: ObservableObject {
    /// UI-facing balance — updated after every operation and on iCloud sync.
    @Published private(set) var balance: Int
    @Published var betAmount: Int = 50
    @Published var isInGame: Bool = false

    /// Canonical in-memory balance — XOR-obfuscated to defeat memory scanners.
    private var secureBalance: ObfuscatedInt

    init() {
        let initial = WalletStore.balance
        self.secureBalance = ObfuscatedInt(initial)
        self.balance = initial

        // Kick off iCloud sync and listen for changes pushed from other devices
        NSUbiquitousKeyValueStore.default.synchronize()
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                let synced = WalletStore.handleiCloudSync()
                guard synced > 0 else { return }
                self.secureBalance = ObfuscatedInt(synced)
                self.balance = synced
            }
        }
    }

    var isBroke: Bool { balance < 10 }

    /// Refreshes balance from iCloud before allowing a bet.
    /// This catches the case where another device spent chips while this device was idle.
    func canPlaceBet(_ amount: Int) -> Bool {
        // Always pull latest from iCloud before checking affordability
        NSUbiquitousKeyValueStore.default.synchronize()
        let cloudBalance = WalletStore.balance
        if cloudBalance < secureBalance.value {
            // Another device spent chips — correct local state
            secureBalance = ObfuscatedInt(cloudBalance)
            balance = cloudBalance
        }
        return secureBalance.value >= amount
    }

    func deduct(_ amount: Int) {
        validateIntegrity()
        // Stamp the deduction time so other devices can detect concurrent bets
        NSUbiquitousKeyValueStore.default.set(Date().timeIntervalSince1970, forKey: "blakjak_last_deduct_ts")
        NSUbiquitousKeyValueStore.default.synchronize()
        let newVal = secureBalance.value - amount
        secureBalance = ObfuscatedInt(newVal)
        balance = newVal
        WalletStore.balance = newVal
    }

    func credit(_ amount: Int) {
        validateIntegrity()
        let newVal = secureBalance.value + amount
        secureBalance = ObfuscatedInt(newVal)
        balance = newVal
        WalletStore.balance = newVal
    }

    func canAfford(_ amount: Int) -> Bool {
        secureBalance.value >= amount
    }

    /// Detects if the published `balance` Int was patched in memory while
    /// `secureBalance` (obfuscated) remained intact. Resets and flags if so.
    private func validateIntegrity() {
        guard balance == secureBalance.value else {
            IntegrityMonitor.flagTamper(.memoryPatch)
            balance = secureBalance.value
            return
        }
    }
}
