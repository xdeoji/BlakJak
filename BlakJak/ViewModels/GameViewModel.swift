import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    @Published var phase: GamePhase = .playerTurn
    @Published var playerHands: [Hand]
    @Published var activeHandIndex: Int = 0
    @Published var dealerHand: Hand
    @Published var dealerHoleRevealed: Bool = false
    @Published var payout: Int = 0
    @Published var pushTax: Int = 0  // amount lost to push tax (0 if no tax)
    @Published var message: String = ""
    @Published var isDoubledDown: [Bool]
    @Published var isSplit: Bool = false
    @Published var handOutcomes: [GameOutcome?] = [nil]
    @Published var tookAction: [Bool]  // true if player hit/doubled/split on this hand

    let betAmount: Int
    let multiplier: Double
    private var deck: Deck

    /// Extra cost charged during the game (double/split) that the view needs to deduct
    @Published var extraDeduction: Int = 0

    init(hand: BlackjackHand, betAmount: Int) {
        self.playerHands = [Hand(cards: hand.playerCards)]
        self.dealerHand = Hand(cards: [hand.dealerUpcard, hand.dealerHoleCard])
        self.deck = hand.remainingDeck
        self.betAmount = betAmount
        self.multiplier = hand.multiplier
        self.isDoubledDown = [false]
        self.tookAction = [false]
        // Check for dealer blackjack after init
        checkDealerBlackjack()
    }

    private func checkDealerBlackjack() {
        guard dealerHand.isBlackjack else { return }
        phase = .dealerTurn

        Task {
            // Dramatic pause before reveal
            try? await Task.sleep(for: .milliseconds(800))

            withAnimation(.spring(response: 0.4)) {
                dealerHoleRevealed = true
            }
            SoundManager.shared.cardFlip()
            Haptics.tap()

            try? await Task.sleep(for: .milliseconds(600))

            if playerHands[0].isBlackjack {
                payout = Int(Double(betAmount) * ProbabilityEngine.pushReturnRate)
                message = "PUSH"
                Haptics.warning()
                SoundManager.shared.push()
                withAnimation(.spring(response: 0.5)) {
                    phase = .resolved(.push)
                }
            } else {
                payout = 0
                message = "DEALER BLACKJACK"
                Haptics.error()
                SoundManager.shared.lose()
                withAnimation(.spring(response: 0.5)) {
                    phase = .resolved(.playerLoses)
                }
            }
        }
    }

    var activeHand: Hand {
        playerHands[activeHandIndex]
    }

    var totalBet: Int {
        var total = 0
        for i in 0..<playerHands.count {
            total += isDoubledDown[i] ? betAmount * 2 : betAmount
        }
        return total
    }

    // MARK: - Player Actions

    func hit() {
        guard phase == .playerTurn, BlackjackRules.canHit(activeHand) else { return }
        tookAction[activeHandIndex] = true
        Haptics.tap()
        SoundManager.shared.cardDeal()

        if let card = deck.draw() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                playerHands[activeHandIndex].add(card)
            }
        }

        if playerHands[activeHandIndex].isBusted {
            handOutcomes[activeHandIndex] = .playerLoses
            Haptics.error()
            advanceOrDealerTurn()
        } else if playerHands[activeHandIndex].value == 21 {
            Haptics.success()
            advanceOrDealerTurn()
        }
    }

    func stand() {
        guard phase == .playerTurn else { return }
        Haptics.medium()
        advanceOrDealerTurn()
    }

    func doubleDown() {
        guard phase == .playerTurn,
              BlackjackRules.canDouble(activeHand) else { return }

        isDoubledDown[activeHandIndex] = true
        tookAction[activeHandIndex] = true
        extraDeduction += betAmount
        Haptics.heavy()
        SoundManager.shared.cardDeal()

        if let card = deck.draw() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                playerHands[activeHandIndex].add(card)
            }
        }

        if playerHands[activeHandIndex].isBusted {
            handOutcomes[activeHandIndex] = .playerLoses
            Haptics.error()
        }
        advanceOrDealerTurn()
    }

    static let maxHands = 4

    func split() {
        guard phase == .playerTurn,
              playerHands.count < Self.maxHands,
              BlackjackRules.canSplit(activeHand) else { return }

        isSplit = true
        extraDeduction += betAmount
        Haptics.heavy()
        SoundManager.shared.cardDeal()

        let card1 = activeHand.cards[0]
        let card2 = activeHand.cards[1]

        var hand1 = Hand(cards: [card1])
        var hand2 = Hand(cards: [card2])

        // Deal one card to each split hand
        if let c1 = deck.draw() { hand1.add(c1) }
        if let c2 = deck.draw() { hand2.add(c2) }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Replace the active hand with the two new hands
            playerHands.remove(at: activeHandIndex)
            playerHands.insert(hand2, at: activeHandIndex)
            playerHands.insert(hand1, at: activeHandIndex)

            isDoubledDown.remove(at: activeHandIndex)
            isDoubledDown.insert(false, at: activeHandIndex)
            isDoubledDown.insert(false, at: activeHandIndex)

            handOutcomes.remove(at: activeHandIndex)
            handOutcomes.insert(nil, at: activeHandIndex)
            handOutcomes.insert(nil, at: activeHandIndex)

            tookAction.remove(at: activeHandIndex)
            tookAction.insert(true, at: activeHandIndex)
            tookAction.insert(true, at: activeHandIndex)
        }
    }

    // MARK: - Hand Progression

    private func advanceOrDealerTurn() {
        // If split, try to move to next hand
        if isSplit && activeHandIndex < playerHands.count - 1 {
            withAnimation(.spring(response: 0.3)) {
                activeHandIndex += 1
            }
            return
        }

        // All hands played, dealer's turn
        // But if all hands busted, skip dealer
        let allBusted = playerHands.allSatisfy { $0.isBusted }
        if allBusted {
            resolveAll()
        } else {
            phase = .dealerTurn
            playDealerTurn()
        }
    }

    // MARK: - Dealer Turn

    private func playDealerTurn() {
        withAnimation(.spring(response: 0.4)) {
            dealerHoleRevealed = true
        }
        SoundManager.shared.cardFlip()
        Haptics.tap()

        Task {
            try? await Task.sleep(for: .milliseconds(600))

            while BlackjackRules.dealerShouldHit(dealerHand) {
                if let card = deck.draw() {
                    SoundManager.shared.cardDeal()
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dealerHand.add(card)
                    }
                    try? await Task.sleep(for: .milliseconds(500))
                } else {
                    break
                }
            }

            resolveAll()
        }
    }

    // MARK: - Resolution

    private func resolveAll() {
        var totalPayout = 0
        var messages: [String] = []

        for i in 0..<playerHands.count {
            let hand = playerHands[i]
            let handBet = isDoubledDown[i] ? betAmount * 2 : betAmount

            // If outcome was already determined (bust during play)
            if let existing = handOutcomes[i], existing == .playerLoses {
                if isSplit { messages.append("Hand \(i + 1): BUST") }
                else { messages.append(hand.isBusted ? "BUST" : "DEALER WINS") }
                continue
            }

            let outcome = BlackjackRules.determineOutcome(
                playerValue: hand.value,
                dealerValue: dealerHand.value,
                playerBusted: hand.isBusted,
                dealerBusted: dealerHand.isBusted,
                playerBlackjack: hand.isBlackjack,
                dealerBlackjack: dealerHand.isBlackjack
            )
            handOutcomes[i] = outcome

            switch outcome {
            case .playerWins:
                totalPayout += Int(Double(handBet) * multiplier)
                messages.append(isSplit ? "Hand \(i + 1): WIN" : "YOU WIN!")
            case .playerBlackjack:
                totalPayout += Int(Double(handBet) * multiplier * 1.5)
                messages.append(isSplit ? "Hand \(i + 1): BLACKJACK" : "BLACKJACK!")
            case .playerLoses:
                messages.append(isSplit ? "Hand \(i + 1): LOSE" : (hand.isBusted ? "BUST" : "DEALER WINS"))
            case .push:
                // Full refund if player took an action, 80% if they just stood
                let pushRate = tookAction[i] ? 1.0 : ProbabilityEngine.pushReturnRate
                let pushPayout = Int(Double(handBet) * pushRate)
                let tax = handBet - pushPayout
                totalPayout += pushPayout
                pushTax += tax
                messages.append(isSplit ? "Hand \(i + 1): PUSH" : "PUSH")
            }
        }

        payout = totalPayout
        message = messages.joined(separator: "\n")

        let overallOutcome: GameOutcome = totalPayout > totalBet ? .playerWins :
                                           totalPayout == 0 ? .playerLoses : .push

        // Sound & haptics for outcome
        switch overallOutcome {
        case .playerWins, .playerBlackjack:
            Haptics.success()
            SoundManager.shared.win()
        case .playerLoses:
            Haptics.error()
            SoundManager.shared.lose()
        case .push:
            Haptics.warning()
            SoundManager.shared.push()
        }

        withAnimation(.spring(response: 0.5)) {
            phase = .resolved(overallOutcome)
        }
    }
}
