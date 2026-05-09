import SwiftUI
import StoreKit

struct BrokeSheet: View {
    @ObservedObject var walletVM: WalletViewModel
    @ObservedObject var chipStore: ChipStore
    @ObservedObject var adManager: RewardedAdManager
    let onDismiss: () -> Void

    @State private var dailyAvailable = DailyBonusStore.isAvailable
    @State private var isShowingAd = false
    @State private var bankBalance = BankStore.balance
    @State private var showWithdrawInput = false
    @State private var withdrawText = ""

    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
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

                        // Free / bank options
                        VStack(spacing: 10) {
                            if bankBalance > 0 {
                                if showWithdrawInput {
                                    bankWithdrawInput
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                } else {
                                    bankRow
                                        .transition(.opacity)
                                }
                            }

                            if dailyAvailable {
                                freeRow(
                                    icon: "calendar.badge.checkmark",
                                    title: "Hourly Bonus",
                                    subtitle: "Free every hour",
                                    chipLabel: "+\(DailyBonusStore.bonusAmount.formatted())",
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
                        .animation(.easeOut(duration: 0.2), value: showWithdrawInput)

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
        .onAppear {
            dailyAvailable = DailyBonusStore.isAvailable
            bankBalance = BankStore.balance
        }
    }

    // MARK: - Bank row

    private var bankRow: some View {
        Button {
            withdrawText = ""
            withAnimation(.easeOut(duration: 0.2)) { showWithdrawInput = true }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundColor(CasinoTheme.warning)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Withdraw from Bank")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(bankBalance.formatted()) available")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(CasinoTheme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CasinoTheme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(CasinoTheme.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CasinoTheme.warning.opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bank withdraw numpad

    private var bankWithdrawInput: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showWithdrawInput = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CasinoTheme.textTertiary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(withdrawText.isEmpty ? "0" : withdrawText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    withdrawText = "\(bankBalance)"
                    Haptics.tick()
                } label: {
                    Text("MAX")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CasinoTheme.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CasinoTheme.warning.opacity(0.12))
                                .overlay(Capsule().strokeBorder(CasinoTheme.warning.opacity(0.3), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }

            Text("available: \(bankBalance.formatted())")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(CasinoTheme.textTertiary)

            let keys: [[String]] = [["1","2","3"],["4","5","6"],["7","8","9"],["C","0","⌫"]]
            VStack(spacing: 6) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { key in
                            Button { handleWithdrawKey(key) } label: {
                                Text(key)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(key == "C" ? CasinoTheme.danger : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(CasinoTheme.bgElevated))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            let amount = Int(withdrawText) ?? 0
            Button {
                guard amount > 0, amount <= bankBalance else { return }
                BankStore.balance -= amount
                bankBalance = BankStore.balance
                walletVM.credit(amount)
                Haptics.heavy()
                onDismiss()
            } label: {
                Text(amount > 0 ? "Withdraw \(amount.formatted())" : "Enter Amount")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(amount > 0 && amount <= bankBalance ? .black : CasinoTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(amount > 0 && amount <= bankBalance ? Color.white : CasinoTheme.bgElevated)
                    )
            }
            .buttonStyle(.plain)
            .disabled(amount <= 0 || amount > bankBalance)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(CasinoTheme.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CasinoTheme.warning.opacity(0.25), lineWidth: 1))
        )
    }

    private func handleWithdrawKey(_ key: String) {
        Haptics.tick()
        switch key {
        case "C": withdrawText = ""
        case "⌫":
            if !withdrawText.isEmpty { withdrawText.removeLast() }
        default:
            if withdrawText == "0" { withdrawText = key }
            else if withdrawText.count < 9 { withdrawText += key }
        }
    }

    // MARK: - Free row

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

    // MARK: - IAP row

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
