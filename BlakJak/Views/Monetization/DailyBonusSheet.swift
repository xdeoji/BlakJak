import SwiftUI

struct DailyBonusSheet: View {
    @ObservedObject var walletVM: WalletViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()

            VStack(spacing: 20) {
                Capsule()
                    .fill(CasinoTheme.border)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 8) {
                    Text("Daily Bonus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("+\(DailyBonusStore.bonusAmount) free chips")
                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                        .foregroundColor(CasinoTheme.textTertiary)
                }

                Button {
                    DailyBonusStore.claim()
                    walletVM.credit(DailyBonusStore.bonusAmount)
                    Haptics.heavy()
                    onDismiss()
                } label: {
                    Text("Claim")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                }
                .buttonStyle(.plain)

                Button {
                    onDismiss()
                } label: {
                    Text("Later")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(CasinoTheme.textTertiary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .preferredColorScheme(.dark)
    }
}
