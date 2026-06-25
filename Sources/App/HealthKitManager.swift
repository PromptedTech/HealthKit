import Foundation
import HealthKit

/// Reads Apple Watch activity-ring data and body-composition data from HealthKit.
/// Also writes body mass and body-fat samples so in-app logging syncs back to Health.
final class HealthKitManager {

    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else { return false }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.workoutType()
        ]
        let shareTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
        ]
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
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

    // MARK: - Body mass

    func latestBodyMass() async -> Double? {
        await latestQuantity(identifier: .bodyMass, unit: .gramUnit(with: .kilo))
    }

    /// Daily body-mass samples (average per day) over the last `days` days, oldest first.
    func bodyMassSeries(days: Int = 90) async -> [(date: Date, kg: Double)] {
        await quantitySeries(identifier: .bodyMass, unit: .gramUnit(with: .kilo), days: days)
            .map { (date: $0.date, kg: $0.value) }
    }

    func saveBodyMass(_ kg: Double, date: Date = Date()) async {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }
        let sample = HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg),
            start: date, end: date
        )
        try? await store.save(sample)
    }

    // MARK: - Body fat percentage

    func latestBodyFat() async -> Double? {
        await latestQuantity(identifier: .bodyFatPercentage, unit: .percent())
    }

    /// Daily body-fat samples (average per day) over the last `days` days, oldest first.
    func bodyFatSeries(days: Int = 90) async -> [(date: Date, pct: Double)] {
        let raw = await quantitySeries(identifier: .bodyFatPercentage, unit: .percent(), days: days)
        return raw.map { ($0.date, $0.value) }
    }

    func saveBodyFat(_ pct: Double, date: Date = Date()) async {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        let sample = HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: .percent(), doubleValue: pct),
            start: date, end: date
        )
        try? await store.save(sample)
    }

    // MARK: - Helpers

    private func latestQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    // MARK: - Workout history

    func recentWorkouts(limit: Int = 30) async -> [HKWorkout] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: nil,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }

    private func quantitySeries(identifier: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async -> [(date: Date, value: Double)] {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -days, to: end)!
        var components = DateComponents()
        components.day = 1
        return await withCheckedContinuation { continuation in
            var results: [(date: Date, value: Double)] = []
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end),
                options: .discreteAverage,
                anchorDate: start,
                intervalComponents: components
            )
            query.initialResultsHandler = { _, collection, _ in
                collection?.enumerateStatistics(from: start, to: end) { stats, _ in
                    if let qty = stats.averageQuantity() {
                        results.append((stats.startDate, qty.doubleValue(for: unit)))
                    }
                }
                continuation.resume(returning: results)
            }
            store.execute(query)
        }
    }
}
