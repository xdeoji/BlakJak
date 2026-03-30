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

    /// Display string: "8/18" for soft hands, "15" for hard hands
    var displayValue: String {
        if isSoft {
            let hardVal = value - 10
            return "\(hardVal)/\(value)"
        }
        return "\(value)"
    }

    var isBusted: Bool { value > 21 }

    var isBlackjack: Bool { cards.count == 2 && value == 21 }

    var canSplit: Bool {
        cards.count == 2 && cards[0].rank.blackjackValue == cards[1].rank.blackjackValue
    }

    mutating func add(_ card: Card) {
        cards.append(card)
    }
}
