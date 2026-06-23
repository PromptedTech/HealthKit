import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity widget (Dynamic Island + Lock Screen)

struct AbsLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AbsActivityAttributes.self) { context in
            // Lock Screen banner / StandBy card
            lockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Long-press expanded view
                DynamicIslandExpandedRegion(.leading) {
                    expandedRingMetric(
                        label: "Move",
                        current: context.state.moveCurrent,
                        goal: context.state.moveGoal,
                        unit: "CAL",
                        colors: ActivityRingsView.moveColors
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedRingMetric(
                        label: "Exer",
                        current: context.state.exerciseCurrent,
                        goal: context.state.exerciseGoal,
                        unit: "MIN",
                        colors: ActivityRingsView.exerciseColors
                    )
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 1) {
                        Text("\(context.state.countdownCount)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("days to go")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(state: context.state)
                }
            } compactLeading: {
                // Small rings pill on the left
                ActivityRingsView(ring: context.state.ring, lineWidth: 3, spacing: 1)
                    .frame(width: 18, height: 18)
                    .padding(.leading, 4)
            } compactTrailing: {
                // Countdown number on the right
                Text("\(context.state.countdownCount)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.trailing, 4)
            } minimal: {
                // Single ring fraction circle when two Live Activities are running
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: context.state.ring.moveFraction)
                        .stroke(ActivityRingsView.moveColors[0], style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 16, height: 16)
            }
        }
    }

    // MARK: - Lock Screen banner

    private func lockScreenView(state: AbsActivityAttributes.ContentState) -> some View {
        HStack(spacing: 12) {
            ActivityRingsView(ring: state.ring, lineWidth: 6, spacing: 2)
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(state.countdownCount) days to go")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if state.bothClosed {
                    Label("Rings closed — good day earned!", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.mint)
                } else {
                    let moveLeft = max(0, state.moveGoal - state.moveCurrent)
                    let exerLeft = max(0, state.exerciseGoal - state.exerciseCurrent)
                    if moveLeft > 0 && exerLeft > 0 {
                        Text("\(Int(moveLeft)) CAL + \(Int(exerLeft)) MIN left to close")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    } else if moveLeft > 0 {
                        Text("\(Int(moveLeft)) CAL left on Move ring")
                            .font(.caption)
                            .foregroundStyle(ActivityRingsView.moveColors[0])
                    } else {
                        Text("\(Int(exerLeft)) MIN left on Exercise ring")
                            .font(.caption)
                            .foregroundStyle(ActivityRingsView.exerciseColors[0])
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text("🔥")
                    .font(.title3)
                Text("\(state.streak)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundStyle(.white)
        .background(.black)
    }

    // MARK: - Expanded Dynamic Island sub-views

    private func expandedRingMetric(
        label: String, current: Double, goal: Double, unit: String, colors: [Color]
    ) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text(goal > 0 ? "\(Int(current))/\(Int(goal))" : "--")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                )
            Text(unit)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(minWidth: 48)
    }

    private func expandedBottom(state: AbsActivityAttributes.ContentState) -> some View {
        Group {
            if state.bothClosed {
                Label("Both rings closed — good day earned!", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.mint)
            } else {
                Text("Close your rings → earn a good day")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.bottom, 6)
    }
}

// MARK: - Preview

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: AbsActivityAttributes()) {
    AbsLiveActivityWidget()
} contentStates: {
    AbsActivityAttributes.ContentState(
        moveCurrent: 420, moveGoal: 600,
        exerciseCurrent: 22, exerciseGoal: 30,
        bothClosed: false, countdownCount: 23, streak: 5
    )
    AbsActivityAttributes.ContentState(
        moveCurrent: 600, moveGoal: 600,
        exerciseCurrent: 30, exerciseGoal: 30,
        bothClosed: true, countdownCount: 22, streak: 6
    )
}

#Preview("Lock Screen", as: .content, using: AbsActivityAttributes()) {
    AbsLiveActivityWidget()
} contentStates: {
    AbsActivityAttributes.ContentState(
        moveCurrent: 420, moveGoal: 600,
        exerciseCurrent: 22, exerciseGoal: 30,
        bothClosed: false, countdownCount: 23, streak: 5
    )
}
