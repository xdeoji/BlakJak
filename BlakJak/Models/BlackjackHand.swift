import Foundation

struct BlackjackHand: Identifiable {
    let id: UUID
    var feedIndex: Int      // position within the current session's feed (1, 2, 3…)
    var lifetimeIndex: Int  // global position across all sessions, never resets
    let playerCards: [Card]
    let dealerUpcard: Card
    let dealerHoleCard: Card
    let multiplier: Double
    let winProbability: Double
    var remainingDeck: Deck

    var playerHand: Hand {
        Hand(cards: playerCards)
    }

    var playerTotal: Int { playerHand.value }
    var playerIsSoft: Bool { playerHand.isSoft }
    var playerIsBusted: Bool { playerHand.isBusted }

    init(playerCards: [Card], dealerUpcard: Card, dealerHoleCard: Card,
         multiplier: Double, winProbability: Double, remainingDeck: Deck,
         feedIndex: Int = 0, lifetimeIndex: Int = 0) {
        self.id = UUID()
        self.feedIndex = feedIndex
        self.lifetimeIndex = lifetimeIndex
        self.playerCards = playerCards
        self.dealerUpcard = dealerUpcard
        self.dealerHoleCard = dealerHoleCard
        self.multiplier = multiplier
        self.winProbability = winProbability
        self.remainingDeck = remainingDeck
    }
}
