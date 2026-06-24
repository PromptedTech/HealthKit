import SwiftUI

/// Transferable wrapper for a rendered PNG so ShareLink can hand it off.
struct ShareableImage: Transferable, Identifiable {
    let id = UUID()
    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) {
            $0.uiImage.pngData() ?? Data()
        }
    }
}

/// The card that gets rendered off-screen and shared as an image.
struct ShareCardView: View {
    let count: Int
    let streak: Int
    let progress: Double

    private var heroColor: Color {
        switch count {
        case 0:        return .mint
        case 1...6:    return .green
        case 7...14:   return .orange
        case 15...29:  return .yellow
        default:       return Color(red: 0.55, green: 0.82, blue: 1.0)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32).fill(Color(white: 0.06))

            RadialGradient(
                colors: [heroColor.opacity(0.25), .clear],
                center: .init(x: 0.5, y: 0.32),
                startRadius: 0, endRadius: 240
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))

            VStack(spacing: 0) {
                Text("ABSCOUNTDOWN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 32)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(heroColor)
                    .shadow(color: heroColor.opacity(0.5), radius: 34)

                Text(count == 0 ? "ABS UNLOCKED 🎉" : "DAYS TO ABS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.4))

                Spacer()

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [heroColor.opacity(0.7), heroColor],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(8, geo.size.width * progress))
                    }
                    .frame(height: 6)
                }
                .frame(height: 6)
                .padding(.horizontal, 32)

                Text("\(Int((progress * 100).rounded()))% of the journey complete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 8)

                Spacer()

                if streak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text("\(streak)-day streak").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(
                        Capsule().fill(.orange.opacity(0.15))
                            .overlay(Capsule().strokeBorder(.orange.opacity(0.3), lineWidth: 1))
                    )
                }

                Spacer()

                Text(count == 0 ? "I crushed it 💪" : "Every ring closed brings me closer 🔥")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 32)
            }
        }
        .frame(width: 340, height: 420)
        .preferredColorScheme(.dark)
    }

    @MainActor
    static func render(count: Int, streak: Int, progress: Double) -> UIImage? {
        let card = ShareCardView(count: count, streak: streak, progress: progress)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}
