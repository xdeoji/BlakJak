import Foundation

enum RiskProfile: String {
    case conservative = "Conservative"
    case balanced = "Balanced"
    case aggressive = "Aggressive"
    case degenerate = "Degen"

    var description: String {
        switch self {
        case .conservative: return "You play it safe — low multipliers, small bets."
        case .balanced: return "A mix of safe plays and calculated risks."
        case .aggressive: return "You chase the big multipliers."
        case .degenerate: return "Max bets on longshots. Respect."
        }
    }
}

@MainActor
class StatsViewModel: ObservableObject {
    @Published var records: [HandRecord] = []

    init() { reload() }

    func reload() {
        records = StatsStore.records
    }

    // MARK: - Core Stats

    var handsPlayed: Int { records.count }

    var totalWagered: Int {
        records.reduce(0) { $0 + $1.betAmount }
    }

    var totalReturned: Int {
        records.reduce(0) { $0 + $1.payout }
    }

    var pnl: Int { totalReturned - totalWagered }

    var winCount: Int { records.filter { $0.wasWin }.count }
    var lossCount: Int { records.filter { !$0.wasWin && !$0.wasPush }.count }
    var pushCount: Int { records.filter { $0.wasPush }.count }

    var winRate: Double {
        guard handsPlayed > 0 else { return 0 }
        return Double(winCount) / Double(handsPlayed)
    }

    var avgBet: Int {
        guard handsPlayed > 0 else { return 0 }
        return totalWagered / handsPlayed
    }

    var avgMultiplier: Double {
        guard handsPlayed > 0 else { return 0 }
        return records.reduce(0.0) { $0 + $1.multiplier } / Double(handsPlayed)
    }

    var biggestWin: Int {
        records.map { $0.payout - $0.betAmount }.max() ?? 0
    }

    var biggestLoss: Int {
        records.map { $0.payout - $0.betAmount }.min() ?? 0
    }

    // MARK: - Risk Profile

    var riskProfile: RiskProfile {
        guard handsPlayed >= 3 else { return .balanced }

        // Score based on two factors:
        // 1. Average multiplier of hands taken (higher = riskier)
        // 2. Bet size relative to typical range (bigger bets = riskier)

        var riskScore = 0.0

        // Multiplier factor: <1.5 = safe, 1.5-2.5 = balanced, 2.5-4 = aggressive, 4+ = degen
        let avgMult = avgMultiplier
        if avgMult < 1.5 { riskScore += 1 }
        else if avgMult < 2.5 { riskScore += 2 }
        else if avgMult < 4.0 { riskScore += 3 }
        else { riskScore += 4 }

        // Bet size factor: proportion of high bets (100+)
        let highBetRatio = Double(records.filter { $0.betAmount >= 100 }.count) / Double(handsPlayed)
        if highBetRatio < 0.15 { riskScore += 1 }
        else if highBetRatio < 0.4 { riskScore += 2 }
        else if highBetRatio < 0.7 { riskScore += 3 }
        else { riskScore += 4 }

        // Big multiplier hands taken (3x+)
        let bigMultRatio = Double(records.filter { $0.multiplier >= 3.0 }.count) / Double(handsPlayed)
        if bigMultRatio < 0.1 { riskScore += 1 }
        else if bigMultRatio < 0.3 { riskScore += 2 }
        else if bigMultRatio < 0.5 { riskScore += 3 }
        else { riskScore += 4 }

        let avg = riskScore / 3.0
        if avg < 1.5 { return .conservative }
        if avg < 2.5 { return .balanced }
        if avg < 3.5 { return .aggressive }
        return .degenerate
    }
}
