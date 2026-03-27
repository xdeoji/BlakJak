import SwiftUI

struct FeedView: View {
    @StateObject private var feedVM = FeedViewModel()
    @StateObject private var walletVM = WalletViewModel()
    @StateObject private var streakVM = StreakViewModel()
    @State private var showProfile = false
    @State private var scrolledID: UUID?
    @State private var activeGame: ActiveGame?

    struct ActiveGame {
        let hand: BlackjackHand
        let betAmount: Int
    }

    private var currentHand: BlackjackHand? {
        guard let id = scrolledID else {
            return feedVM.hands.first
        }
        return feedVM.hands.first(where: { $0.id == id })
    }

    private var currentHandIsPlayable: Bool {
        guard let hand = currentHand else { return false }
        return !feedVM.isPlayed(hand.id) && activeGame == nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            CasinoTheme.bg.ignoresSafeArea()

            // Feed
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(feedVM.hands) { hand in
                        HandCardView(hand: hand, feedVM: feedVM)
                            .containerRelativeFrame(.vertical)
                            .clipped()
                            .onAppear {
                                feedVM.loadMoreIfNeeded(hand: hand)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $scrolledID)
            .scrollDisabled(activeGame != nil)

            // Game overlay
            if let game = activeGame {
                InlineGameView(
                    hand: game.hand,
                    betAmount: game.betAmount,
                    walletVM: walletVM,
                    feedVM: feedVM,
                    streakVM: streakVM,
                    onFinish: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            activeGame = nil
                            walletVM.isInGame = false
                        }
                    }
                )
                .background(CasinoTheme.bg)
                .transition(.opacity)
            }

            // Top bar
            VStack(spacing: 6) {
                HStack {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(CasinoTheme.textSecondary)
                    }

                    Spacer()

                    Text("blakjak")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)

                    Spacer()

                    BalanceView(balance: walletVM.balance)
                }

                if streakVM.winStreak >= 3 || streakVM.lossStreak >= 3 {
                    StreakBanner(streakVM: streakVM)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Bottom wager overlay
            if currentHandIsPlayable {
                VStack {
                    Spacer()
                    BetPicker(amount: $walletVM.betAmount, balance: walletVM.balance) {
                        guard let hand = currentHand,
                              walletVM.betAmount <= walletVM.balance else { return }
                        Haptics.heavy()
                        SoundManager.shared.buyIn()
                        let bet = walletVM.betAmount
                        walletVM.deduct(bet)
                        walletVM.isInGame = true
                        withAnimation(.easeOut(duration: 0.2)) {
                            activeGame = ActiveGame(hand: hand, betAmount: bet)
                        }
                    }
                }
                .ignoresSafeArea(.keyboard)
                .transition(.move(edge: .bottom))
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfile) {
            ProfileView(walletVM: walletVM, streakVM: streakVM)
        }
    }
}
