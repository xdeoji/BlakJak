import Foundation

struct BlackjackRules {
    /// Dealer stands on all 17s (including soft 17)
    static func dealerShouldHit(_ hand: Hand) -> Bool {
        hand.value < 17
    }

    /// Play out the dealer's hand, drawing from the deck
    static func playDealerHand(_ hand: inout Hand, deck: inout Deck) {
        while dealerShouldHit(hand) {
            if let card = deck.draw() {
                hand.add(card)
            } else {
                break
            }
        }
    }

    /// Determine outcome: player vs dealer
    static func determineOutcome(playerValue: Int, dealerValue: Int,
                                  playerBusted: Bool, dealerBusted: Bool,
                                  playerBlackjack: Bool, dealerBlackjack: Bool) -> GameOutcome {
        if playerBusted { return .playerLoses }
        if playerBlackjack && !dealerBlackjack { return .playerBlackjack }
        if dealerBlackjack && !playerBlackjack { return .playerLoses }
        if playerBlackjack && dealerBlackjack { return .push }
        if dealerBusted { return .playerWins }
        if playerValue > dealerValue { return .playerWins }
        if playerValue < dealerValue { return .playerLoses }
        return .push
    }

    /// Can the player hit on this hand?
    static func canHit(_ hand: Hand) -> Bool {
        !hand.isBusted && hand.value < 21
    }

    /// Can the player double down? (only with 2 cards, total 9-11 typically, but we allow any 2-card hand)
    static func canDouble(_ hand: Hand) -> Bool {
        hand.cards.count == 2 && !hand.isBusted
    }

    /// Can the player split?
    static func canSplit(_ hand: Hand) -> Bool {
        hand.canSplit
    }
}
