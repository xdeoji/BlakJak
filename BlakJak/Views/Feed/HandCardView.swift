import SwiftUI

let cardW: CGFloat = 64
let cardH: CGFloat = 92

func cardOverlap(for count: Int) -> CGFloat {
    switch count {
    case ...2: return -18
    case 3:    return -32
    case 4:    return -40
    default:   return -44
    }
}

struct HandCardView: View {
    let hand: BlackjackHand
    @State private var appeared = false

    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()
            content
        }
        .clipped()
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("DEALER")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(CasinoTheme.textTertiary)
                    .tracking(2)
                HStack(spacing: -18) {
                    PlayingCardView(card: hand.dealerUpcard, width: cardW, height: cardH)
                    PlayingCardView(card: hand.dealerHoleCard, isFaceDown: true, width: cardW, height: cardH)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : -20)

            Spacer().frame(height: 32)

            MultiplierBadge(multiplier: hand.multiplier)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.9)

            handInfo
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 32)

            previewPlayerSection
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()

            // Fixed bottom spacer — same height always for consistent paging
            Spacer().frame(height: 140)
        }
        .padding(.horizontal, 24)
    }

    private var previewPlayerSection: some View {
        let overlap = cardOverlap(for: hand.playerCards.count)

        return VStack(spacing: 8) {
            HStack(spacing: overlap) {
                ForEach(Array(hand.playerCards.enumerated()), id: \.element.id) { index, card in
                    PlayingCardView(card: card, width: cardW, height: cardH)
                        .zIndex(Double(index))
                }
            }

            HStack(spacing: 6) {
                Text("YOU")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(CasinoTheme.textTertiary)
                    .tracking(2)
                Text("\(hand.playerTotal)")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }

    private var handInfo: some View {
        HStack(spacing: 12) {
            infoChip(label: "\(Int(hand.winProbability * 100))%", sublabel: "win")
            if hand.playerIsSoft {
                infoChip(label: "soft", sublabel: nil)
            }
        }
    }

    private func infoChip(label: String, sublabel: String?) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(CasinoTheme.textSecondary)
            if let sub = sublabel {
                Text(sub)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(CasinoTheme.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(CasinoTheme.bgElevated)
                .overlay(Capsule().strokeBorder(CasinoTheme.border, lineWidth: 1))
        )
    }
}
