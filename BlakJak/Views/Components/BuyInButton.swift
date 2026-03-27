import SwiftUI

struct BuyInButton: View {
    let amount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("Buy In")
                    .font(.system(size: 16, weight: .semibold))
                Text("·")
                    .foregroundColor(.white.opacity(0.3))
                Text("\(amount) pts")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
        }
        .buttonStyle(.plain)
    }
}
