import Foundation
import SwiftUI

enum Suit: String, CaseIterable, Codable, Hashable {
    case hearts, diamonds, clubs, spades

    var symbol: String {
        switch self {
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        case .spades: return "♠"
        }
    }

    var color: Color {
        switch self {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .white
        }
    }
}

enum Rank: Int, CaseIterable, Codable, Hashable {
    case ace = 1
    case two, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king

    var display: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rawValue)"
        }
    }

    var blackjackValue: Int {
        switch self {
        case .ace: return 11
        case .jack, .queen, .king: return 10
        default: return rawValue
        }
    }
}

struct Card: Identifiable, Codable, Hashable {
    let id: UUID
    let rank: Rank
    let suit: Suit

    init(rank: Rank, suit: Suit) {
        self.id = UUID()
        self.rank = rank
        self.suit = suit
    }
}
