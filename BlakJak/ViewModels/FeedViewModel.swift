import Foundation

@MainActor
class FeedViewModel: ObservableObject {
    @Published var hands: [BlackjackHand] = []
    @Published var playedHandIDs: Set<UUID> = []

    private let generator = HandGenerator()
    private let initialBatchSize = 5
    private let loadMoreThreshold = 2
    private let loadMoreCount = 3

    init() {
        generateInitialBatch()
    }

    func generateInitialBatch() {
        hands = (0..<initialBatchSize).map { _ in generator.generateHand() }
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        if currentIndex >= hands.count - loadMoreThreshold {
            let newHands = (0..<loadMoreCount).map { _ in generator.generateHand() }
            hands.append(contentsOf: newHands)
        }
    }

    func loadMoreIfNeeded(hand: BlackjackHand) {
        guard let index = hands.firstIndex(where: { $0.id == hand.id }) else { return }
        loadMoreIfNeeded(currentIndex: index)
    }

    func markPlayed(_ id: UUID) {
        playedHandIDs.insert(id)
    }

    func isPlayed(_ id: UUID) -> Bool {
        playedHandIDs.contains(id)
    }
}
