import SwiftUI

struct InlineGameView: View {
    let hand: BlackjackHand
    let betAmount: Int
    @ObservedObject var walletVM: WalletViewModel
    @ObservedObject var feedVM: FeedViewModel
    @ObservedObject var streakVM: StreakViewModel
    let onFinish: () -> Void
    @StateObject private var gameVM: GameViewModel
    @State private var hasCredited = false
    @State private var lastExtraDeduction = 0

    init(hand: BlackjackHand, betAmount: Int, walletVM: WalletViewModel,
         feedVM: FeedViewModel, streakVM: StreakViewModel, onFinish: @escaping () -> Void) {
        self.hand = hand
        self.betAmount = betAmount
        self.walletVM = walletVM
        self.feedVM = feedVM
        self.streakVM = streakVM
        self.onFinish = onFinish
        self._gameVM = StateObject(wrappedValue: GameViewModel(hand: hand, betAmount: betAmount))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Dealer
            dealerSection

            Spacer().frame(height: 32)

            // Bet info
            betInfo

            Spacer().frame(height: 32)

            // Player
            playerSection

            Spacer()

            // Controls or result
            Group {
                if gameVM.phase == .playerTurn {
                    GameControlsView(gameVM: gameVM, walletVM: walletVM)
                } else if gameVM.phase.isResolved {
                    resultView
                } else {
                    HStack(spacing: 6) {
                        ProgressView()
                            .tint(CasinoTheme.textTertiary)
                            .scaleEffect(0.8)
                        Text("Dealer playing")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(CasinoTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer().frame(height: 140)
        }
        .padding(.horizontal, 24)
        .onChange(of: gameVM.extraDeduction) { _, newValue in
            let delta = newValue - lastExtraDeduction
            if delta > 0 {
                walletVM.deduct(delta)
                lastExtraDeduction = newValue
            }
        }
    }

    // MARK: - Dealer

    private var dealerSection: some View {
        let overlap = cardOverlap(for: gameVM.dealerHand.cards.count)

        return VStack(spacing: 8) {
            Text("DEALER")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(2)

            HStack(spacing: overlap) {
                PlayingCardView(card: gameVM.dealerHand.cards[0], width: cardW, height: cardH)

                ForEach(Array(gameVM.dealerHand.cards.dropFirst().enumerated()), id: \.offset) { index, card in
                    if index == 0 && !gameVM.dealerHoleRevealed {
                        PlayingCardView(card: card, isFaceDown: true, width: cardW, height: cardH)
                    } else {
                        PlayingCardView(card: card, width: cardW, height: cardH)
                    }
                }
            }

            if gameVM.dealerHoleRevealed {
                Text(gameVM.dealerHand.displayValue)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(CasinoTheme.textSecondary)
            }
        }
    }

    // MARK: - Player

    private var playerSection: some View {
        Group {
            if gameVM.isSplit {
                splitCarousel
            } else {
                singleHandView(hand: gameVM.playerHands[0], index: 0, isActive: true)
            }
        }
    }

    private var splitCarousel: some View {
        GeometryReader { geo in
            let handWidth: CGFloat = 140
            let spacing: CGFloat = 12
            let totalWidth = handWidth + spacing
            let centerOffset = (geo.size.width - handWidth) / 2
            let xOffset = centerOffset - CGFloat(gameVM.activeHandIndex) * totalWidth

            HStack(spacing: spacing) {
                ForEach(0..<gameVM.playerHands.count, id: \.self) { handIndex in
                    let isActive = handIndex == gameVM.activeHandIndex
                        && (gameVM.phase == .playerTurn || gameVM.phase == .dealerTurn || gameVM.phase.isResolved)
                    singleHandView(hand: gameVM.playerHands[handIndex], index: handIndex, isActive: isActive)
                        .frame(width: handWidth)
                }
            }
            .offset(x: xOffset)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: gameVM.activeHandIndex)
        }
        .frame(height: cardH + 40)
        .padding(.horizontal, -24)
    }

    private func singleHandView(hand: Hand, index: Int, isActive: Bool) -> some View {
        let overlap = cardOverlap(for: hand.cards.count)

        return VStack(spacing: 6) {
            HStack(spacing: overlap) {
                ForEach(Array(hand.cards.enumerated()), id: \.element.id) { cardIndex, card in
                    PlayingCardView(card: card, width: cardW, height: cardH)
                        .zIndex(Double(cardIndex))
                }
            }

            HStack(spacing: 6) {
                if gameVM.isSplit {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? .white : CasinoTheme.textTertiary)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(isActive ? CasinoTheme.bgElevated : Color.clear)
                                .overlay(Circle().strokeBorder(CasinoTheme.border, lineWidth: 1))
                        )
                } else {
                    Text("YOU")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(CasinoTheme.textTertiary)
                        .tracking(2)
                }
                Text(hand.displayValue)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundColor(hand.isBusted ? CasinoTheme.danger : .white)

                if gameVM.isDoubledDown[index] {
                    Text("2x")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CasinoTheme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(CasinoTheme.bgElevated)
                                .overlay(Capsule().strokeBorder(CasinoTheme.border, lineWidth: 1))
                        )
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            gameVM.isSplit ?
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? CasinoTheme.bgElevated.opacity(0.5) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isActive ? CasinoTheme.borderLight : Color.clear, lineWidth: 1)
                    )
                : nil
        )
        .opacity(gameVM.isSplit && !isActive && gameVM.phase == .playerTurn ? 0.5 : 1.0)
    }

    // MARK: - Bet Info

    private var potentialPayout: Int {
        let base = Int(Double(gameVM.totalBet) * hand.multiplier)
        let bonus = streakVM.totalBonusMultiplier
        return bonus > 1.0 ? Int(Double(base) * bonus) : base
    }

    private var betInfo: some View {
        VStack(spacing: 0) {
            HStack {
                statBlock(label: "BET", value: "\(gameVM.totalBet)")
                Spacer()
                Rectangle().fill(CasinoTheme.border).frame(width: 1, height: 28)
                Spacer()
                statBlock(label: "WIN %", value: "\(liveWinPercent)%", color: winPercentColor)
                Spacer()
                Rectangle().fill(CasinoTheme.border).frame(width: 1, height: 28)
                Spacer()
                statBlock(label: "TO WIN", value: "\(potentialPayout)")
            }

            // Streak info line
            HStack(spacing: 8) {
                if hand.winProbability < 0.60 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("streak eligible")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(CasinoTheme.success.opacity(0.7))
                }

                if streakVM.totalBonusMultiplier > 1.0 {
                    HStack(spacing: 3) {
                        Text("·")
                            .foregroundColor(CasinoTheme.textTertiary)
                        Text("\(String(format: "%.1fx", streakVM.totalBonusMultiplier)) bonus")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(CasinoTheme.success.opacity(0.7))
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CasinoTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                )
        )
    }

    private func statBlock(label: String, value: String, color: Color = .white) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(1)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
                .contentTransition(.numericText())
        }
    }

    private var liveWinPercent: Int {
        let activeHand = gameVM.activeHand
        if activeHand.isBusted { return 0 }
        let playerVal = activeHand.value

        if gameVM.dealerHoleRevealed {
            let dealerVal = gameVM.dealerHand.value
            let dealerBusted = gameVM.dealerHand.isBusted
            let dealerDone = dealerBusted || dealerVal >= 17

            if dealerDone {
                // Dealer is finished drawing — exact outcome
                if dealerBusted { return 100 }
                if playerVal > dealerVal { return 100 }
                if playerVal == dealerVal { return 50 }
                return 0
            }

            // Dealer still drawing — use probability table with known dealer total
            // Estimate: what % of the time does the dealer end up < playerVal or bust?
            let dealerUpcardVal = hand.dealerUpcard.rank == .ace ? 11 :
                                  min(hand.dealerUpcard.rank.blackjackValue, 10)
            let (pWin, pPush) = ProbabilityEngine.outcomeProbabilitiesOnStand(
                playerTotal: playerVal, dealerUpcardValue: dealerUpcardVal)
            return max(1, min(99, Int((pWin + pPush * 0.5) * 100)))
        }

        // Before reveal, use probability table
        let dealerUpcardVal = hand.dealerUpcard.rank == .ace ? 11 :
                              min(hand.dealerUpcard.rank.blackjackValue, 10)
        let prob = ProbabilityEngine.effectiveWinProbability(
            playerTotal: playerVal,
            isSoft: activeHand.isSoft,
            dealerUpcardValue: dealerUpcardVal
        )
        // Clamp to 1-99 to avoid showing 0% or 100% when outcome isn't certain
        return max(1, min(99, Int(prob * 100)))
    }

    private var winPercentColor: Color {
        if liveWinPercent >= 60 { return CasinoTheme.success }
        if liveWinPercent >= 40 { return CasinoTheme.warning }
        return CasinoTheme.danger
    }

    // MARK: - Result

    @State private var showPushExplainer = false

    private var resultView: some View {
        VStack(spacing: 8) {
            Text(gameVM.message)
                .font(.system(size: gameVM.isSplit ? 16 : 24, weight: .bold))
                .foregroundColor(resultColor)
                .multilineTextAlignment(.center)

            if finalPayout > 0 {
                VStack(spacing: 4) {
                    Text("+\(gameVM.payout) pts")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(CasinoTheme.textSecondary)

                    if streakBonusAmount > 0 {
                        Text("+\(streakBonusAmount) streak reward")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(CasinoTheme.success)
                    }
                }
            }

            // Taxes breakdown
            VStack(spacing: 6) {

                if gameVM.pushTax > 0 {
                    resultPill(
                        icon: "exclamationmark.triangle.fill",
                        text: "-\(gameVM.pushTax) push tax",
                        color: CasinoTheme.danger
                    )
                    .onTapGesture { showPushExplainer.toggle() }

                    if showPushExplainer {
                        Text("Standing without acting costs 20% on a push. Hit, double, or split to avoid the tax.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(CasinoTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .transition(.opacity)
                    }
                }

                if let wb = streakVM.activeWinBonus, streakBonusApplied <= 1.0 {
                    resultPill(
                        icon: "flame.fill",
                        text: "Next: \(wb.label)",
                        color: CasinoTheme.success.opacity(0.5)
                    )
                }
                if let lb = streakVM.activeLossBonus, streakBonusApplied <= 1.0 {
                    resultPill(
                        icon: "arrow.up.circle.fill",
                        text: "Next win: \(lb.label)",
                        color: CasinoTheme.warning.opacity(0.5)
                    )
                }
            }

            Button {
                onFinish()
            } label: {
                Text("Continue")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .onAppear {
            guard !hasCredited else { return }
            hasCredited = true

            let payout = finalPayout
            if payout > 0 {
                walletVM.credit(payout)
            }
            feedVM.markPlayed(hand.id)

            // Record streak
            if case .resolved(let outcome) = gameVM.phase {
                streakVM.recordOutcome(outcome, winProbability: hand.winProbability)
            }

            // Record stats
            let wasWin: Bool
            let wasPush: Bool
            if case .resolved(let outcome) = gameVM.phase {
                wasWin = outcome == .playerWins || outcome == .playerBlackjack
                wasPush = outcome == .push
            } else {
                wasWin = false
                wasPush = false
            }
            StatsStore.record(HandRecord(
                betAmount: gameVM.totalBet,
                multiplier: hand.multiplier,
                payout: payout,
                wasWin: wasWin,
                wasPush: wasPush,
                timestamp: Date()
            ))
        }
    }

    /// Streak bonus multiplier captured before recording (so loss streak bonus applies to this win)
    private var streakBonusApplied: Double {
        guard gameVM.payout > 0 else { return 1.0 }
        if case .resolved(let outcome) = gameVM.phase {
            if outcome == .playerWins || outcome == .playerBlackjack {
                return streakVM.totalBonusMultiplier
            }
        }
        return 1.0
    }

    private var streakBonusAmount: Int {
        guard streakBonusApplied > 1.0 else { return 0 }
        return Int(Double(gameVM.payout) * streakBonusApplied) - gameVM.payout
    }

    private var finalPayout: Int {
        return gameVM.payout + streakBonusAmount
    }

    private func resultPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var resultColor: Color {
        if case .resolved(let outcome) = gameVM.phase {
            switch outcome {
            case .playerWins, .playerBlackjack: return CasinoTheme.success
            case .playerLoses: return CasinoTheme.danger
            case .push: return CasinoTheme.textSecondary
            }
        }
        return .white
    }
}
