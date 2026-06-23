import SwiftUI

/// Lightweight SwiftUI confetti — a Canvas particle burst with no third-party deps.
/// Drops ~70 colored pieces that fall and drift, fading out over ~3 seconds.
struct ConfettiView: View {
    var pieceCount = 70

    private struct Piece {
        let x: Double          // 0...1 horizontal start
        let delay: Double      // seconds before this piece starts
        let duration: Double   // fall duration
        let drift: Double      // horizontal drift, points
        let size: Double
        let spin: Double
        let color: Color
    }

    private let pieces: [Piece]
    private let start = Date()

    init(pieceCount: Int = 70) {
        self.pieceCount = pieceCount
        let palette: [Color] = [.red, .pink, .orange, .yellow, .green, .mint, .blue, .purple]
        pieces = (0..<pieceCount).map { _ in
            Piece(
                x: Double.random(in: 0...1),
                delay: Double.random(in: 0...0.8),
                duration: Double.random(in: 1.8...3.2),
                drift: Double.random(in: -60...60),
                size: Double.random(in: 6...11),
                spin: Double.random(in: -360...360),
                color: palette.randomElement()!
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let t = now - piece.delay
                    guard t > 0 else { continue }
                    let progress = min(1, t / piece.duration)
                    let y = -20 + progress * (size.height + 40)
                    let x = piece.x * size.width + piece.drift * progress
                    let opacity = 1 - progress

                    var rect = context
                    rect.translateBy(x: x, y: y)
                    rect.rotate(by: .degrees(piece.spin * progress))
                    rect.opacity = opacity
                    let path = Path(roundedRect: CGRect(
                        x: -piece.size / 2, y: -piece.size / 2,
                        width: piece.size, height: piece.size * 0.6
                    ), cornerRadius: 1.5)
                    rect.fill(path, with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
