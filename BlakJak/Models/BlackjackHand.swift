import Foundation

struct BlackjackHand: Identifiable {
    let id: UUID
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
         multiplier: Double, winProbability: Double, remainingDeck: Deck) {
        self.id = UUID()
        self.playerCards = playerCards
        self.dealerUpcard = dealerUpcard
        self.dealerHoleCard = dealerHoleCard
        self.multiplier = multiplier
        self.winProbability = winProbability
        self.remainingDeck = remainingDeck
    }
}
