import SwiftUI

struct OnboardingView: View {
    @State private var page = 0
    let onComplete: () -> Void

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "hand.draw",
            "Scroll. Find. Play.",
            "Swipe through an endless feed of blackjack hands at various stages. Each one is a unique situation waiting for you."
        ),
        (
            "chart.bar",
            "Every Hand Has a Price",
            "The multiplier reflects your odds. Easy hands pay less. Hard hands pay more. You decide what's worth the risk."
        ),
        (
            "dollarsign.circle",
            "Buy In to Play",
            "Pick your wager and buy into any hand. You'll take over from where it is — hit, stand, double, or split to finish it."
        ),
        (
            "exclamationmark.triangle",
            "Pushes Cost You",
            "If you tie the dealer without acting, you lose 20% of your bet. Hit, double, or split to avoid the push tax."
        ),
        (
            "flame",
            "Streaks Reward You",
            "Win a hand under 60% odds and it counts toward your win streak. The riskier the hand, the bigger the bonus. Loss streaks also boost your next win. Look for the flame icon to know a hand is streak-eligible."
        )
    ]

    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: pages[page].icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .id(page) // force re-render for transition

                Spacer().frame(height: 32)

                // Title
                Text(pages[page].title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .id("title\(page)")

                Spacer().frame(height: 16)

                // Body
                Text(pages[page].body)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(CasinoTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .id("body\(page)")

                Spacer()

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.white : CasinoTheme.textTertiary)
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer().frame(height: 32)

                // Button
                Button {
                    Haptics.medium()
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            page += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Let's Go")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                // Skip
                if page < pages.count - 1 {
                    Button {
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CasinoTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                }

                Spacer().frame(height: 40)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -30 && page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                    } else if value.translation.width > 30 && page > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) { page -= 1 }
                    }
                }
        )
    }
}
