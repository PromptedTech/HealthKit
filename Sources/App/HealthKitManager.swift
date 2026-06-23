import Foundation
import HealthKit

/// Reads Apple Watch activity-ring data from HealthKit.
/// A day is a "good day" only when both the Move and Exercise rings are closed.
final class HealthKitManager {

    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else { return false }
        let types: Set<HKObjectType> = [HKObjectType.activitySummaryType()]
        do {
            try await store.requestAuthorization(toShare: [], read: types)
            return true
        } catch {
            return false
        }
    }

    /// Move/Exercise current values and goals for the given calendar day.
    /// Returns `.empty` when no summary exists (Watch not worn / no data / not authorized).
    func ringData(for date: Date) async -> RingData {
        await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.calendar = calendar

            let predicate = HKQuery.predicate(
                forActivitySummariesBetweenStart: components,
                end: components
            )

            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, _ in
                guard let summary = summaries?.first else {
                    continuation.resume(returning: .empty)
                    return
                }

                let data = RingData(
                    moveCurrent: summary.activeEnergyBurned.doubleValue(for: .kilocalorie()),
                    moveGoal: summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()),
                    exerciseCurrent: summary.appleExerciseTime.doubleValue(for: .minute()),
                    exerciseGoal: summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                )
                continuation.resume(returning: data)
            }

            store.execute(query)
        }
    }
}
