import SwiftUI

struct iCloudRequiredView: View {
    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "icloud.slash.fill")
                        .font(.system(size: 56))
                        .foregroundColor(CasinoTheme.textTertiary)

                    VStack(spacing: 8) {
                        Text("iCloud Required")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("BlakJak uses iCloud to keep your balance and purchased chips safe across devices and reinstalls.\n\nSign in to iCloud in Settings to continue.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(CasinoTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(CasinoTheme.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(CasinoTheme.border, lineWidth: 1))
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
