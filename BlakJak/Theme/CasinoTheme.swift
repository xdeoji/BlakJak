import SwiftUI

struct CasinoTheme {
    // Core palette — near-black backgrounds, white text, minimal accent
    static let bg = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let bgCard = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let bgElevated = Color(red: 0.14, green: 0.14, blue: 0.14)
    static let border = Color.white.opacity(0.08)
    static let borderLight = Color.white.opacity(0.12)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.5)
    static let textTertiary = Color.white.opacity(0.3)

    // Accent — muted warm white / off-gold, not bright gold
    static let accent = Color(red: 0.92, green: 0.88, blue: 0.78)
    static let accentMuted = Color(red: 0.92, green: 0.88, blue: 0.78).opacity(0.6)

    // Semantic
    static let success = Color(red: 0.3, green: 0.85, blue: 0.5)
    static let danger = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.3)

    // Card back
    static let cardBack = Color(red: 0.12, green: 0.12, blue: 0.15)

    // Background gradient — very subtle
    static var bgGradient: LinearGradient {
        LinearGradient(
            colors: [bg, Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
