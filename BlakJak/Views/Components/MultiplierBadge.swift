import SwiftUI

struct MultiplierBadge: View {
    let multiplier: Double

    var body: some View {
        HStack(spacing: 2) {
            Text(formattedMultiplier)
                .font(.system(size: 42, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text("x")
                .font(.system(size: 22, weight: .medium, design: .monospaced))
                .foregroundColor(CasinoTheme.textSecondary)
        }
    }

    private var formattedMultiplier: String {
        if multiplier >= 10.0 { return "10.0" }
        return String(format: "%.1f", multiplier)
    }
}
