#if os(iOS)
import ActivityKit
import Foundation

/// Attributes for the "rings still open" Live Activity.
/// The activity starts when the app opens with unclosed rings and ends when
/// both rings close (or at midnight if rings never closed).
struct AbsActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var moveCurrent: Double
        var moveGoal: Double
        var exerciseCurrent: Double
        var exerciseGoal: Double
        var bothClosed: Bool
        var countdownCount: Int
        var streak: Int
    }
}

extension AbsActivityAttributes.ContentState {
    var ring: RingData {
        RingData(
            moveCurrent: moveCurrent,
            moveGoal: moveGoal,
            exerciseCurrent: exerciseCurrent,
            exerciseGoal: exerciseGoal
        )
    }
}
#endif
