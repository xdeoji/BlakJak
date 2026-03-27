import SwiftUI

struct PlayingCardView: View {
    let card: Card
    var isFaceDown: Bool = false
    var width: CGFloat = 58
    var height: CGFloat = 84

    // Scale factor relative to default size
    private var scale: CGFloat { width / 58.0 }
    private var cardColor: Color {
        card.suit.color == .white ? Color(white: 0.15) : card.suit.color
    }

    var body: some View {
        ZStack {
            if isFaceDown {
                cardBack
            } else {
                cardFront
            }
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    private var cardFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6 * scale)
                .fill(.white)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(card.rank.display)
                            .font(.system(size: 12 * scale, weight: .semibold, design: .monospaced))
                        Text(card.suit.symbol)
                            .font(.system(size: 10 * scale))
                    }
                    .foregroundColor(cardColor)
                    Spacer()
                }
                .padding(.leading, 5 * scale)
                .padding(.top, 4 * scale)

                Spacer()

                Text(card.suit.symbol)
                    .font(.system(size: 22 * scale))
                    .foregroundColor(cardColor)

                Spacer()

                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(card.suit.symbol)
                            .font(.system(size: 10 * scale))
                        Text(card.rank.display)
                            .font(.system(size: 12 * scale, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(cardColor)
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 5 * scale)
                .padding(.bottom, 4 * scale)
            }
        }
    }

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6 * scale)
                .fill(CasinoTheme.cardBack)

            RoundedRectangle(cornerRadius: 4 * scale)
                .fill(CasinoTheme.bg)
                .padding(3 * scale)

            VStack(spacing: 5 * scale) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 20 * scale, height: 1)
                }
            }

            RoundedRectangle(cornerRadius: 6 * scale)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
