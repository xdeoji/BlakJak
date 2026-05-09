import SwiftUI

struct FeedView: View {
    @StateObject private var feedVM = FeedViewModel()
    @StateObject private var walletVM = WalletViewModel()
    @StateObject private var streakVM = StreakViewModel()
    @StateObject private var chipStore = ChipStore.shared
    @StateObject private var adManager = RewardedAdManager.shared
    @State private var showProfile = false
    @State private var showBrokeSheet = false
    @State private var showDailyBonus = false
    @State private var activeGame: ActiveGame?
    @State private var currentPage = 0
    @State private var previousPage = 0

    struct ActiveGame {
        let hand: BlackjackHand
        let betAmount: Int
    }

    private var currentHand: BlackjackHand? {
        guard currentPage < feedVM.hands.count else { return nil }
        return feedVM.hands[currentPage]
    }

    private var currentHandIsPlayable: Bool {
        guard let hand = currentHand else { return false }
        return !feedVM.isPlayed(hand.id) && activeGame == nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            CasinoTheme.bg.ignoresSafeArea()

            // Feed
            VerticalPager(
                currentPage: $currentPage,
                pageCount: feedVM.hands.count,
                content: { index in
                    HandCardView(hand: feedVM.hands[index])
                },
                isScrollEnabled: activeGame == nil
            )
            .ignoresSafeArea()
            .onChange(of: currentPage) { _, newPage in
                feedVM.loadMoreIfNeeded(currentIndex: newPage)

                // Skip detection: player scrolled forward past an unplayed, non-active hand
                if newPage > previousPage && activeGame == nil {
                    let skippedIndex = previousPage
                    if skippedIndex < feedVM.hands.count {
                        let skippedHand = feedVM.hands[skippedIndex]
                        if !feedVM.isPlayed(skippedHand.id) {
                            feedVM.recordSkip(skippedHand)
                            AnalyticsManager.shared.trackHandSkipped(
                                hand: skippedHand,
                                consecutiveSkips: feedVM.consecutiveSkips
                            )
                        }
                    }
                }
                previousPage = newPage
            }

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
                        // Advance to next hand
                        if currentPage + 1 < feedVM.hands.count {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                currentPage += 1
                            }
                        }
                    }
                )
                .ignoresSafeArea()
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

                    Button { showBrokeSheet = true } label: {
                        BalanceView(balance: walletVM.balance)
                    }
                    .buttonStyle(.plain)
                }

                if streakVM.winStreak >= 3 || streakVM.lossStreak >= 3 {
                    StreakBanner(streakVM: streakVM)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Bottom wager overlay
            VStack {
                Spacer()
                if currentHandIsPlayable {
                    if walletVM.isBroke {
                        topUpFooter
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        BetPicker(amount: $walletVM.betAmount, balance: walletVM.balance) {
                            guard let hand = currentHand,
                                  walletVM.betAmount <= walletVM.balance else { return }
                            Haptics.heavy()
                            SoundManager.shared.buyIn()
                            let bet = walletVM.betAmount
                            let balanceBefore = walletVM.balance
                            let skipsBefore = feedVM.consecutiveSkips
                            let wasSkipped = feedVM.wasSkipped(hand)
                            walletVM.deduct(bet)
                            walletVM.isInGame = true
                            AnalyticsManager.shared.trackHandStarted(
                                hand: hand,
                                betAmount: bet,
                                balance: balanceBefore,
                                consecutiveSkipsBefore: skipsBefore,
                                returnedToSkipped: wasSkipped
                            )
                            withAnimation(.easeOut(duration: 0.2)) {
                                activeGame = ActiveGame(hand: hand, betAmount: bet)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else if let hand = currentHand, feedVM.isPlayed(hand.id), activeGame == nil {
                    playedFooter
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.keyboard)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentHandIsPlayable)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentPage)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: walletVM.isBroke)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Show daily bonus sheet once per session if available and not broke
            if DailyBonusStore.isAvailable && !walletVM.isBroke {
                showDailyBonus = true
            }
        }
        .onChange(of: walletVM.balance) { _, newBalance in
            // Only trigger if not mid-hand — player may win and recover
            if newBalance < 10 && !showBrokeSheet && activeGame == nil {
                showBrokeSheet = true
            }
        }
        .onChange(of: walletVM.isInGame) { _, inGame in
            // Check after hand resolves in case balance is still too low to play
            if !inGame && walletVM.isBroke && !showBrokeSheet {
                showBrokeSheet = true
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(walletVM: walletVM, streakVM: streakVM)
        }
        .sheet(isPresented: $showBrokeSheet) {
            BrokeSheet(
                walletVM: walletVM,
                chipStore: chipStore,
                adManager: adManager,
                onDismiss: { showBrokeSheet = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showDailyBonus) {
            DailyBonusSheet(walletVM: walletVM, onDismiss: { showDailyBonus = false })
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.hidden)
        }
    }

    private var topUpFooter: some View {
        Button { showBrokeSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(CasinoTheme.accent)
                Text("Top Up to Play")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CasinoTheme.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                CasinoTheme.bgCard
                    .overlay(Rectangle().fill(CasinoTheme.border).frame(height: 1), alignment: .top)
            )
        }
        .buttonStyle(.plain)
    }

    private var playedFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(CasinoTheme.textTertiary)
            Text("Hand Played")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            CasinoTheme.bgCard
                .overlay(Rectangle().fill(CasinoTheme.border).frame(height: 1), alignment: .top)
        )
    }
}
