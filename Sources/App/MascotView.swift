import SwiftUI

/// Shows mascot_idle when rings aren't done, mascot_done when both rings are closed.
/// Drop your images into Assets.xcassets → mascot_idle and mascot_done imagesets.
struct MascotView: View {
    var ringsClosed: Bool
    var size: CGFloat = 90

    @State private var bounce = false
    @State private var showDone = false

    var body: some View {
        Group {
            if showDone, let img = UIImage(named: "mascot_done") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else if let img = UIImage(named: "mascot_idle") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                // Placeholder shown until you drop your images in
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        )
                    VStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Add image")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(bounce ? 1.06 : 1.0)
        .offset(y: bounce ? -4 : 0)
        .onAppear { startAnimations() }
        .onChange(of: ringsClosed) { _, closed in
            if closed { withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { showDone = true } }
            else { showDone = false }
        }
    }

    private func startAnimations() {
        showDone = ringsClosed
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            bounce = true
        }
    }
}
