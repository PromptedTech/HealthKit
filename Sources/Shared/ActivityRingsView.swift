import SwiftUI

/// Apple Fitness-style concentric activity rings.
/// Outer = Move (red/pink), inner = Exercise (green). Shared by the app and the widget.
struct ActivityRingsView: View {
    var ring: RingData
    var lineWidth: CGFloat = 16
    var spacing: CGFloat = 6
    /// When true, the rings sweep up from empty on appear (used in the app, not the widget).
    var animated: Bool = false

    @State private var appeared = false

    static let moveColors = [Color(red: 0.98, green: 0.16, blue: 0.34),
                             Color(red: 0.99, green: 0.33, blue: 0.58)]
    static let exerciseColors = [Color(red: 0.40, green: 0.95, blue: 0.20),
                                 Color(red: 0.66, green: 1.00, blue: 0.30)]

    /// Fraction actually rendered — 0 until `appeared` flips when `animated`.
    private var displayScale: Double { (animated && !appeared) ? 0 : 1 }

    var body: some View {
        GeometryReader { geo in
            let dim = min(geo.size.width, geo.size.height)
            ZStack {
                ring(fraction: ring.moveFraction * displayScale,
                     colors: Self.moveColors,
                     diameter: dim)
                ring(fraction: ring.exerciseFraction * displayScale,
                     colors: Self.exerciseColors,
                     diameter: dim - 2 * (lineWidth + spacing))
            }
            .frame(width: dim, height: dim)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.easeOut(duration: 0.9)) { appeared = true }
        }
    }

    private func ring(fraction: Double, colors: [Color], diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(colors[0].opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, fraction))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: colors + [colors[0]]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: fraction)
        }
        .frame(width: diameter, height: diameter)
    }
}
