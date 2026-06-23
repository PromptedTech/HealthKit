import ActivityKit
import Foundation

/// Manages the "rings still open" Live Activity that lives on the Dynamic Island
/// and iPhone Lock Screen throughout the day.
/// • Starts when the app wakes and today's rings are still open
/// • Updates each time EvaluationEngine refreshes ring data
/// • Ends (with a 4-hour linger) the moment both rings close
@MainActor
final class LiveActivityManager {

    static let shared = LiveActivityManager()

    private var currentActivity: Activity<AbsActivityAttributes>?

    // MARK: - Public interface

    func startOrUpdate(ring: RingData, count: Int, streak: Int) {
        let state = makeState(ring: ring, count: count, streak: streak)
        if let activity = runningActivity() {
            Task {
                let content = ActivityContent(state: state, staleDate: nextMidnight())
                await activity.update(content)
            }
        } else {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let attributes = AbsActivityAttributes()
            do {
                let content = ActivityContent(state: state, staleDate: nextMidnight())
                currentActivity = try Activity.request(attributes: attributes, content: content)
            } catch {
                // Older device / simulator — Live Activities not supported; silently ignore.
            }
        }
    }

    func end(ring: RingData, count: Int, streak: Int) {
        guard let activity = runningActivity() else { return }
        let state = makeState(ring: ring, count: count, streak: streak)
        Task {
            let finalContent = ActivityContent(state: state, staleDate: nil)
            // Linger for 4 hours so the user can see the "closed!" celebration.
            await activity.end(finalContent, dismissalPolicy: .after(Date().addingTimeInterval(4 * 3600)))
            currentActivity = nil
        }
    }

    func endAllStale() {
        Task {
            for activity in Activity<AbsActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
    }

    // MARK: - Helpers

    private func runningActivity() -> Activity<AbsActivityAttributes>? {
        if let cached = currentActivity,
           cached.activityState == .active || cached.activityState == .stale {
            return cached
        }
        // Re-attach to any activity started in a previous app session.
        currentActivity = Activity<AbsActivityAttributes>.activities.first {
            $0.activityState == .active || $0.activityState == .stale
        }
        return currentActivity
    }

    private func makeState(ring: RingData, count: Int, streak: Int) -> AbsActivityAttributes.ContentState {
        AbsActivityAttributes.ContentState(
            moveCurrent: ring.moveCurrent,
            moveGoal: ring.moveGoal,
            exerciseCurrent: ring.exerciseCurrent,
            exerciseGoal: ring.exerciseGoal,
            bothClosed: ring.bothClosed,
            countdownCount: count,
            streak: streak
        )
    }

    private func nextMidnight() -> Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
        return cal.startOfDay(for: tomorrow)
    }
}
