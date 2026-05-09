import StoreKit

// Product IDs must match what you create in App Store Connect
enum ChipProductID: String, CaseIterable {
    case small  = "blakjak.chips.10000"
    case medium = "blakjak.chips.50000"
    case large  = "blakjak.chips.150000"

    var chips: Int {
        switch self {
        case .small:  return 10_000
        case .medium: return 50_000
        case .large:  return 150_000
        }
    }
}

@MainActor
class ChipStore: ObservableObject {
    static let shared = ChipStore()

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var listenerTask: Task<Void, Error>?

    init() {
        listenerTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        listenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            let ids = ChipProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
            // Sort by price ascending
            products.sort { $0.price < $1.price }
        } catch {
            print("ChipStore: product load failed – \(error)")
        }
    }

    func purchase(_ product: Product, walletVM: WalletViewModel) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                let chips = ChipProductID(rawValue: product.id)?.chips ?? 0
                if chips > 0 { walletVM.credit(chips) }
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase pending. Check your payment method."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
            print("ChipStore: purchase error – \(error)")
        }
    }

    func chips(for product: Product) -> Int {
        ChipProductID(rawValue: product.id)?.chips ?? 0
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                }
            }
        }
    }
}
