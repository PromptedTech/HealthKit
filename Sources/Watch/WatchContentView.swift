import SwiftUI

struct WatchContentView: View {

    @State private var count  = CountdownStore.currentCount
    @State private var ring   = CountdownStore.todayRing
    @State private var streak = CountdownStore.currentStreak

    // ETA — read raw keys directly; ProgressStore.swift can't compile on watchOS (UIImage)
    @State private var etaState = ""
    @State private var etaDate: Date?
    @State private var etaWeeks: Double = 0

    private static let ud = UserDefaults(suiteName: "group.com.nakul.abscountdown")

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                countdownHero
                ringsCard
                streakPill
                etaChip
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
        .background(Color.black)
        .onAppear { refresh() }
    }

    // MARK: - Sections

    private var countdownHero: some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("days to go")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.top, 4)
    }

    private var ringsCard: some View {
        VStack(spacing: 8) {
            ActivityRingsView(ring: ring, lineWidth: 7, spacing: 3)
                .frame(width: 70, height: 70)

            HStack(spacing: 18) {
                ringMetric(
                    "Move",
                    Int(ring.moveCurrent), ring.moveGoal, "CAL",
                    ActivityRingsView.moveColors[0]
                )
                ringMetric(
                    "Exer",
                    Int(ring.exerciseCurrent), ring.exerciseGoal, "MIN",
                    ActivityRingsView.exerciseColors[0]
                )
            }

            if ring.bothClosed {
                Label("Rings closed!", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.mint)
            }
        }
    }

    private var streakPill: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.callout)
            Text(streak == 1 ? "1-day streak" : "\(streak)-day streak")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.12), in: Capsule())
    }

    @ViewBuilder
    private var etaChip: some View {
        switch etaState {
        case "onTrack":
            if let date = etaDate {
                VStack(spacing: 2) {
                    Text("Abs by")
                        .font(.system(size: 9))
                        .foregroundStyle(.mint.opacity(0.7))
                    Text(date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.mint)
                    if etaWeeks > 0 {
                        Text("≈\(Int(etaWeeks))w away")
                            .font(.system(size: 9))
                            .foregroundStyle(.mint.opacity(0.7))
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        case "alreadyThere":
            Text("Target reached! 🎉")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.green)
        case "notLosingYet":
            Text("Not in a deficit yet")
                .font(.system(size: 10))
                .foregroundStyle(.orange.opacity(0.8))
        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private func ringMetric(_ label: String, _ val: Int, _ goal: Double, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
            Text(goal > 0 ? "\(val)/\(Int(goal))" : "--")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    private func refresh() {
        count  = CountdownStore.currentCount
        ring   = CountdownStore.todayRing
        streak = CountdownStore.currentStreak
        etaState = Self.ud?.string(forKey: "progressCachedETAState") ?? ""
        etaDate  = Self.ud?.object(forKey: "progressCachedETADate") as? Date
        etaWeeks = Self.ud?.double(forKey: "progressCachedETAWeeks") ?? 0
    }
}

#Preview {
    WatchContentView()
}
