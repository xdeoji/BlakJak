import Foundation

struct HandGenerator {
    /// Maximum number of re-rolls when a hand hits 21 (to reduce 21s in feed)
    private let maxRerolls = 3

    /// Generate a random mid-play blackjack hand for the feed
    /// Hands totaling 21 are re-rolled most of the time to prevent cherry-picking
    func generateHand() -> BlackjackHand {
        for _ in 0..<maxRerolls {
            let hand = generateRawHand()
            // Keep 21s only ~15% of the time
            if hand.playerTotal == 21 && Double.random(in: 0..<1) > 0.15 {
                continue
            }
            return hand
        }
        // After max rerolls, return whatever we get
        return generateRawHand()
    }

    private func generateRawHand() -> BlackjackHand {
        var deck = Deck.shoe(deckCount: 2)

        let dealerUpcard = deck.draw()!
        let dealerHoleCard = deck.draw()!

        // If dealer has blackjack, hand never progresses past opening deal
        let dealerHand = Hand(cards: [dealerUpcard, dealerHoleCard])
        let dealerHasBJ = dealerHand.isBlackjack

        let playerCardCount = dealerHasBJ ? 2 : weightedRandomCardCount()
        var playerCards = deck.draw(2)

        var tempHand = Hand(cards: playerCards)

        if !dealerHasBJ {
            var additionalCards = playerCardCount - 2
            while additionalCards > 0 && !tempHand.isBusted && tempHand.value < 21 {
                if let card = deck.draw() {
                    playerCards.append(card)
                    tempHand = Hand(cards: playerCards)
                    additionalCards -= 1
                } else {
                    break
                }
            }

            // If player busted during generation, remove last card(s) to keep hand playable
            while tempHand.isBusted && playerCards.count > 2 {
                playerCards.removeLast()
                tempHand = Hand(cards: playerCards)
            }
        }

        let dealerValue = dealerUpcard.rank == .ace ? 11 :
                          min(dealerUpcard.rank.blackjackValue, 10)
        let (mult, winProb) = ProbabilityEngine.calculateMultiplier(
            playerTotal: tempHand.value,
            isSoft: tempHand.isSoft,
            dealerUpcardValue: dealerValue
        )

        return BlackjackHand(
            playerCards: playerCards,
            dealerUpcard: dealerUpcard,
            dealerHoleCard: dealerHoleCard,
            multiplier: mult,
            winProbability: winProb,
            remainingDeck: deck
        )
    }

    /// Weighted random: 40% 2-card, 35% 3-card, 20% 4-card, 5% 5-card
    private func weightedRandomCardCount() -> Int {
        let roll = Double.random(in: 0..<1)
        if roll < 0.40 { return 2 }
        if roll < 0.75 { return 3 }
        if roll < 0.95 { return 4 }
        return 5
    }
}
