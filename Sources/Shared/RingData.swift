import Foundation

/// A snapshot of the two activity rings we care about for a single day.
struct RingData: Sendable, Equatable {
    var moveCurrent: Double      // active kilocalories burned
    var moveGoal: Double         // move goal in kilocalories
    var exerciseCurrent: Double  // exercise minutes
    var exerciseGoal: Double     // exercise goal in minutes

    var moveClosed: Bool { moveGoal > 0 && moveCurrent >= moveGoal }
    var exerciseClosed: Bool { exerciseGoal > 0 && exerciseCurrent >= exerciseGoal }

    /// 0...1+ fill fraction (can exceed 1 when the goal is beaten).
    var moveFraction: Double { moveGoal > 0 ? moveCurrent / moveGoal : 0 }
    var exerciseFraction: Double { exerciseGoal > 0 ? exerciseCurrent / exerciseGoal : 0 }

    /// Both rings closed = today is on track to count as a good day.
    var bothClosed: Bool { moveClosed && exerciseClosed }

    static let empty = RingData(moveCurrent: 0, moveGoal: 0, exerciseCurrent: 0, exerciseGoal: 0)

    static let sample = RingData(moveCurrent: 420, moveGoal: 800, exerciseCurrent: 35, exerciseGoal: 60)
}
