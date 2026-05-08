import SwiftUI
import StoreKit

struct BrokeSheet: View {
    @ObservedObject var walletVM: WalletViewModel
    @ObservedObject var chipStore: ChipStore
    @ObservedObject var adManager: RewardedAdManager
    let onDismiss: () -> Void

    @State private var dailyAvailable = DailyBonusStore.isAvailable
    @State private var isShowingAd = false

    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(CasinoTheme.border)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 6) {
                            Text("Out of Chips")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                            Text("Top up to keep playing")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(CasinoTheme.textTertiary)
                        }
                        .padding(.top, 20)

                        // Free options
                        VStack(spacing: 10) {
                            if dailyAvailable {
                                freeRow(
                                    icon: "calendar.badge.checkmark",
                                    title: "Daily Bonus",
                                    subtitle: "Free every 24 hours",
                                    chipLabel: "+\(DailyBonusStore.bonusAmount)",
                                    color: CasinoTheme.success
                                ) {
                                    DailyBonusStore.claim()
                                    walletVM.credit(DailyBonusStore.bonusAmount)
                                    dailyAvailable = false
                                    Haptics.heavy()
                                    onDismiss()
                                }
                            }

                            if adManager.isAdAvailable {
                                freeRow(
                                    icon: "play.rectangle.fill",
                                    title: "Watch an Ad",
                                    subtitle: "Short video, free chips",
                                    chipLabel: "+\(RewardedAdManager.chipReward)",
                                    color: CasinoTheme.accent
                                ) {
                                    isShowingAd = true
                                    adManager.showAd {
                                        walletVM.credit(RewardedAdManager.chipReward)
                                        Haptics.heavy()
                                    } onDismiss: {
                                        isShowingAd = false
                                        onDismiss()
                                    }
                                }
                            }
                        }

                        // Divider
                        HStack {
                            Rectangle().fill(CasinoTheme.border).frame(height: 1)
                            Text("OR BUY")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(CasinoTheme.textTertiary)
                                .tracking(1.5)
                                .fixedSize()
                            Rectangle().fill(CasinoTheme.border).frame(height: 1)
                        }

                        // IAP products
                        if chipStore.products.isEmpty {
                            ProgressView()
                                .tint(CasinoTheme.textTertiary)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(chipStore.products, id: \.id) { product in
                                    chipBundleRow(product: product)
                                }
                            }
                        }

                        if let error = chipStore.errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(CasinoTheme.danger)
                                .multilineTextAlignment(.center)
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { dailyAvailable = DailyBonusStore.isAvailable }
    }

    // MARK: - Free Row

    private func freeRow(icon: String, title: String, subtitle: String,
                         chipLabel: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(CasinoTheme.textTertiary)
                }

                Spacer()

                Text(chipLabel)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(color.opacity(0.15))
                            .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(CasinoTheme.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CasinoTheme.border, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .disabled(isShowingAd)
    }

    // MARK: - IAP Row

    private func chipBundleRow(product: Product) -> some View {
        let chips = chipStore.chips(for: product)

        return Button {
            Task { await chipStore.purchase(product, walletVM: walletVM) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(CasinoTheme.warning)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName.isEmpty ? "\(chips.formatted()) Chips" : product.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("+\(chips.formatted()) chips")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(CasinoTheme.textTertiary)
                }

                Spacer()

                if chipStore.isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Text(product.displayPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(CasinoTheme.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CasinoTheme.border, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .disabled(chipStore.isPurchasing)
        .onChange(of: walletVM.balance) { _, newBalance in
            if newBalance >= 10 { onDismiss() }
        }
    }
}
