import Foundation

enum GameOutcome: Equatable {
    case playerWins
    case playerLoses
    case push
    case playerBlackjack
}

enum GamePhase: Equatable {
    case preview
    case playerTurn
    case dealerTurn
    case resolved(GameOutcome)

    var isResolved: Bool {
        if case .resolved = self { return true }
        return false
    }
}
