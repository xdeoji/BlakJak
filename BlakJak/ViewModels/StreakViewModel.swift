import Foundation

struct StreakBonus {
    let multiplierBonus: Double  // e.g., 1.2 means payout * 1.2
    let label: String
}

@MainActor
class StreakViewModel: ObservableObject {
    @Published var winStreak: Int
    @Published var lossStreak: Int
    @Published var enabled: Bool
    @Published var lastMilestone: StreakMilestone?

    init() {
        self.winStreak = StreakStore.winStreak
        self.lossStreak = StreakStore.lossStreak
        self.enabled = StreakStore.streaksEnabled
    }

    // MARK: - Win Streak Thresholds

    /// Win streak bonus: multiplier applied on top of hand multiplier
    /// Only counts wins on hands below 60% win probability
    var activeWinBonus: StreakBonus? {
        guard enabled else { return nil }
        switch winStreak {
        case 3...4: return StreakBonus(multiplierBonus: 1.2, label: "3x Win Streak · 1.2x bonus")
        case 5...9: return StreakBonus(multiplierBonus: 1.5, label: "\(winStreak)x Win Streak · 1.5x bonus")
        case 10...: return StreakBonus(multiplierBonus: 2.0, label: "\(winStreak)x Win Streak · 2x bonus")
        default: return nil
        }
    }

    // MARK: - Loss Streak Thresholds

    /// Loss streak: increases the multiplier of the next winning hand
    var activeLossBonus: StreakBonus? {
        guard enabled else { return nil }
        switch lossStreak {
        case 3...4: return StreakBonus(multiplierBonus: 1.3, label: "3x Loss Streak · 1.3x next win")
        case 5...6: return StreakBonus(multiplierBonus: 1.6, label: "\(lossStreak)x Loss Streak · 1.6x next win")
        case 7...: return StreakBonus(multiplierBonus: 2.0, label: "\(lossStreak)x Loss Streak · 2x next win")
        default: return nil
        }
    }

    /// Combined bonus multiplier to apply to a win payout
    var totalBonusMultiplier: Double {
        guard enabled else { return 1.0 }
        var bonus = 1.0
        if let wb = activeWinBonus { bonus *= wb.multiplierBonus }
        if let lb = activeLossBonus { bonus *= lb.multiplierBonus }
        return bonus
    }

    // MARK: - Recording Outcomes

    /// Call after a hand resolves. winProbability is the hand's pre-play win prob.
    func recordOutcome(_ outcome: GameOutcome, winProbability: Double) {
        guard enabled else { return }

        switch outcome {
        case .playerWins, .playerBlackjack:
            // Win streak only counts if hand was below 60% win probability
            if winProbability < 0.60 {
                winStreak += 1
            }
            // Any win resets loss streak
            checkMilestone(type: .win, count: winStreak)
            lossStreak = 0

        case .playerLoses:
            lossStreak += 1
            checkMilestone(type: .loss, count: lossStreak)
            winStreak = 0

        case .push:
            // Push doesn't break either streak
            break
        }

        StreakStore.winStreak = winStreak
        StreakStore.lossStreak = lossStreak
    }

    func toggleEnabled() {
        enabled.toggle()
        StreakStore.streaksEnabled = enabled
        if !enabled {
            // Reset streaks when disabled
            winStreak = 0
            lossStreak = 0
            StreakStore.winStreak = 0
            StreakStore.lossStreak = 0
        }
    }

    // MARK: - Milestones

    private func checkMilestone(type: StreakMilestone.Kind, count: Int) {
        if count == 3 || count == 5 || count == 7 || count == 10 || count % 5 == 0 {
            lastMilestone = StreakMilestone(kind: type, count: count)
            Haptics.heavy()
            SoundManager.shared.streak()
        }
    }
}

struct StreakMilestone: Equatable {
    enum Kind: Equatable { case win, loss }
    let kind: Kind
    let count: Int
}
