import Foundation

struct Deck {
    var cards: [Card]

    static func shoe(deckCount: Int = 6) -> Deck {
        var cards: [Card] = []
        for _ in 0..<deckCount {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    cards.append(Card(rank: rank, suit: suit))
                }
            }
        }
        cards.shuffle()
        return Deck(cards: cards)
    }

    mutating func draw() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }

    mutating func draw(_ count: Int) -> [Card] {
        var drawn: [Card] = []
        for _ in 0..<count {
            if let card = draw() {
                drawn.append(card)
            }
        }
        return drawn
    }
}
