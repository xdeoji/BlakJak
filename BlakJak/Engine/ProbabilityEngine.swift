import Foundation

struct ProbabilityEngine {
    // Dealer final total probability distribution given upcard
    // Source: Wizard of Odds infinite-deck dealer probability tables
    // Format: [dealerUpcardValue: [17: p, 18: p, 19: p, 20: p, 21: p, bust: p]]
    // Dealer upcard value: A=11, 2-9=face, 10=10/J/Q/K
    // "bust" is represented as key 0

    private static let dealerOutcomes: [Int: [Int: Double]] = [
        // Upcard 2
        2: [17: 0.1395, 18: 0.1335, 19: 0.1300, 20: 0.1236, 21: 0.1199, 0: 0.3535],
        // Upcard 3
        3: [17: 0.1337, 18: 0.1297, 19: 0.1261, 20: 0.1218, 21: 0.1163, 0: 0.3724],
        // Upcard 4
        4: [17: 0.1304, 18: 0.1259, 19: 0.1216, 20: 0.1162, 21: 0.1122, 0: 0.3937],
        // Upcard 5
        5: [17: 0.1219, 18: 0.1228, 19: 0.1189, 20: 0.1167, 21: 0.1083, 0: 0.4114],
        // Upcard 6
        6: [17: 0.1654, 18: 0.1063, 19: 0.1063, 20: 0.1008, 21: 0.0985, 0: 0.4227],
        // Upcard 7
        7: [17: 0.3686, 18: 0.1378, 19: 0.0786, 20: 0.0786, 21: 0.0741, 0: 0.2623],
        // Upcard 8
        8: [17: 0.1286, 18: 0.3594, 19: 0.1286, 20: 0.0688, 21: 0.0688, 0: 0.2458],
        // Upcard 9
        9: [17: 0.1197, 18: 0.1197, 19: 0.3519, 20: 0.1197, 21: 0.0605, 0: 0.2285],
        // Upcard 10 (10, J, Q, K)
        10: [17: 0.1117, 18: 0.1117, 19: 0.1117, 20: 0.3396, 21: 0.0344, 0: 0.2109],
        // Upcard Ace
        11: [17: 0.1310, 18: 0.1310, 19: 0.1310, 20: 0.1310, 21: 0.3644, 0: 0.1116]
    ]

    /// Push returns 80% of bet, so pushes cost the player 20% of their wager
    static let pushReturnRate = 0.80

    /// Calculate win and push probabilities if player stands on current total
    static func outcomeProbabilitiesOnStand(playerTotal: Int, dealerUpcardValue: Int) -> (pWin: Double, pPush: Double) {
        guard playerTotal <= 21, let outcomes = dealerOutcomes[dealerUpcardValue] else {
            return (0.0, 0.0)
        }

        var pWin = 0.0
        var pPush = 0.0

        // Player wins if dealer busts
        pWin += outcomes[0] ?? 0.0

        // Compare against each dealer final total
        for dealerTotal in 17...21 {
            let prob = outcomes[dealerTotal] ?? 0.0
            if playerTotal > dealerTotal {
                pWin += prob
            } else if playerTotal == dealerTotal {
                pPush += prob
            }
        }

        return (pWin, pPush)
    }

    /// For hands that are mid-play and could still hit, estimate effective expected return
    /// Factors in: P(win) * multiplier_payout + P(push) * pushReturnRate + P(lose) * 0
    /// Returns effective win probability (adjusted for push penalty) used to set the multiplier
    static func effectiveWinProbability(playerTotal: Int, isSoft: Bool,
                                         dealerUpcardValue: Int) -> Double {
        let (standWin, standPush) = outcomeProbabilitiesOnStand(
            playerTotal: playerTotal, dealerUpcardValue: dealerUpcardValue)
        // Effective probability = P(win) + P(push) * pushReturnRate
        // This bakes the push penalty into the multiplier so it reflects true expected return
        let standProb = standWin + standPush * pushReturnRate

        // For totals 17+, player should almost always stand (basic strategy)
        if playerTotal >= 17 && !isSoft {
            return standProb
        }

        // For soft hands 17+, slightly boost (can hit safely)
        if isSoft && playerTotal >= 17 {
            return min(standProb * 1.05, 0.95)
        }

        // For totals 12-16 (stiff hands), hitting gives slightly better odds than standing
        // The boost represents the option value of being able to improve the hand
        if playerTotal >= 12 && playerTotal <= 16 {
            let hitBoost: Double
            switch playerTotal {
            case 12: hitBoost = 0.08
            case 13: hitBoost = 0.06
            case 14: hitBoost = 0.04
            case 15: hitBoost = 0.03
            case 16: hitBoost = 0.02
            default: hitBoost = 0.0
            }
            return min(standProb + hitBoost, 0.90)
        }

        // For low totals (4-11), player will definitely hit and has good improvement potential
        if playerTotal <= 11 {
            // These hands have significant option value
            let baseProb: Double
            if isSoft {
                baseProb = 0.50 + Double(playerTotal - 12) * 0.03
            } else {
                switch playerTotal {
                case 11: baseProb = 0.58
                case 10: baseProb = 0.55
                case 9:  baseProb = 0.50
                case 8:  baseProb = 0.47
                default: baseProb = 0.44
                }
            }
            // Adjust for dealer strength
            let dealerStrength: Double
            switch dealerUpcardValue {
            case 2...6: dealerStrength = 1.08
            case 7...9: dealerStrength = 0.95
            default: dealerStrength = 0.88  // 10, A
            }
            return min(baseProb * dealerStrength, 0.90)
        }

        return standProb
    }

    /// Calculate the payout multiplier for a hand
    /// multiplier = houseFactor / effectiveWinProb, clamped to reasonable range
    /// effectiveWinProb already accounts for push penalty (pushes return only 80%)
    static func multiplier(effectiveWinProbability: Double) -> Double {
        guard effectiveWinProbability > 0.01 else { return 10.0 }
        let raw = 0.95 / effectiveWinProbability
        return min(max(raw, 1.05), 10.0)
    }

    /// Convenience: get multiplier directly from hand state
    static func calculateMultiplier(playerTotal: Int, isSoft: Bool,
                                     dealerUpcardValue: Int) -> (multiplier: Double, winProb: Double) {
        let effProb = effectiveWinProbability(playerTotal: playerTotal,
                                               isSoft: isSoft,
                                               dealerUpcardValue: dealerUpcardValue)
        let mult = multiplier(effectiveWinProbability: effProb)
        return (mult, effProb)
    }
}
