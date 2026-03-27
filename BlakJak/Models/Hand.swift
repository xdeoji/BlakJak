import Foundation

struct Hand {
    var cards: [Card]

    var value: Int {
        var total = 0
        var aces = 0
        for card in cards {
            total += card.rank.blackjackValue
            if card.rank == .ace { aces += 1 }
        }
        while total > 21 && aces > 0 {
            total -= 10
            aces -= 1
        }
        return total
    }

    var isSoft: Bool {
        var total = 0
        var aces = 0
        for card in cards {
            total += card.rank.blackjackValue
            if card.rank == .ace { aces += 1 }
        }
        while total > 21 && aces > 0 {
            total -= 10
            aces -= 1
        }
        return aces > 0 && total <= 21
    }

    var isBusted: Bool { value > 21 }

    var isBlackjack: Bool { cards.count == 2 && value == 21 }

    var canSplit: Bool {
        cards.count == 2 && cards[0].rank == cards[1].rank
    }

    mutating func add(_ card: Card) {
        cards.append(card)
    }
}
