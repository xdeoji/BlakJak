import Foundation

@MainActor
class FeedViewModel: ObservableObject {
    @Published var hands: [BlackjackHand] = []
    @Published var playedHandIDs: Set<UUID> = []

    private let generator = HandGenerator()
    private let initialBatchSize = 5
    private let loadMoreThreshold = 2
    private let loadMoreCount = 3

    /// Hands that were scrolled past without being played.
    private(set) var skippedHandIDs: Set<UUID> = []
    /// How many hands in a row the player has skipped (resets on play).
    private(set) var consecutiveSkips: Int = 0
    /// Feed position counter for this session (1-based).
    private var sessionHandCount: Int = 0

    init() {
        generateInitialBatch()
    }

    func generateInitialBatch() {
        hands = (0..<initialBatchSize).map { _ in stampedHand() }
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        if currentIndex >= hands.count - loadMoreThreshold {
            let newHands = (0..<loadMoreCount).map { _ in stampedHand() }
            hands.append(contentsOf: newHands)
        }
    }

    func loadMoreIfNeeded(hand: BlackjackHand) {
        guard let index = hands.firstIndex(where: { $0.id == hand.id }) else { return }
        loadMoreIfNeeded(currentIndex: index)
    }

    func markPlayed(_ id: UUID) {
        playedHandIDs.insert(id)
        consecutiveSkips = 0
    }

    func isPlayed(_ id: UUID) -> Bool {
        playedHandIDs.contains(id)
    }

    /// Call when the player scrolls past a hand without playing it.
    func recordSkip(_ hand: BlackjackHand) {
        skippedHandIDs.insert(hand.id)
        consecutiveSkips += 1
    }

    /// Whether this hand was previously skipped (player returned to it).
    func wasSkipped(_ hand: BlackjackHand) -> Bool {
        skippedHandIDs.contains(hand.id)
    }

    // MARK: - Private

    private func stampedHand() -> BlackjackHand {
        sessionHandCount += 1
        let lifetime = SettingsStore.incrementAndGetLifetimeHandCount()
        var hand = generator.generateHand()
        hand.feedIndex = sessionHandCount
        hand.lifetimeIndex = lifetime
        return hand
    }
}
