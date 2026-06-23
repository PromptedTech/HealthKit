import Foundation
import WidgetKit

/// Settles each calendar day's outcome:
///   - both rings closed  -> good day (-1)
///   - otherwise          -> bad day (+1)
///
/// Completed days (before today) are settled in a catch-up loop, so the counter
/// self-corrects even if the app/background task did not run for several days.
/// Today is credited *immediately* the moment both rings close (rings can't re-open),
/// giving instant feedback; if today ends still open, tomorrow's run settles it as a
/// bad day.
@MainActor
final class EvaluationEngine {

    static let shared = EvaluationEngine()

    private let health = HealthKitManager.shared

    func runCatchUp() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Settle every fully-completed day we haven't settled yet.
        var day = calendar.date(byAdding: .day, value: 1, to: CountdownStore.lastSettledDate)!
        while day <= yesterday {
            let ring = CountdownStore.applyingGoalOverrides(to: await health.ringData(for: day))
            CountdownStore.recordRing(day, ring)
            if ring.bothClosed {
                CountdownStore.applyGoodDay()
                CountdownStore.recordDay(day, good: true)
            } else {
                CountdownStore.applyBadDay()
                CountdownStore.recordDay(day, good: false)
            }
            CountdownStore.lastSettledDate = day
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }

        // Refresh today's live ring values for the UI / widget.
        let todayRing = CountdownStore.applyingGoalOverrides(to: await health.ringData(for: Date()))
        CountdownStore.todayRing = todayRing
        CountdownStore.recordRing(Date(), todayRing)

        // Give instant credit the moment both rings close today.
        // If rings are still open, leave lastSettledDate untouched — tomorrow's
        // catch-up loop will penalize this day when it becomes "yesterday".
        if CountdownStore.lastSettledDate < today && todayRing.bothClosed {
            CountdownStore.applyGoodDay()
            CountdownStore.recordDay(today, good: true)
            CountdownStore.lastSettledDate = today
        }

        // Update the Dynamic Island / Lock Screen Live Activity with the latest ring values.
        // End it (with a celebration linger) when both rings close; otherwise start/update.
        if todayRing.bothClosed {
            LiveActivityManager.shared.end(
                ring: todayRing,
                count: CountdownStore.currentCount,
                streak: CountdownStore.currentStreak
            )
        } else {
            LiveActivityManager.shared.startOrUpdate(
                ring: todayRing,
                count: CountdownStore.currentCount,
                streak: CountdownStore.currentStreak
            )
        }

        // Schedule / cancel the 7 PM "rings still open" nudge based on today's status.
        NotificationManager.shared.syncReminder(ringsClosed: todayRing.bothClosed)

        // Re-arm the weekend recap with the latest week-to-date averages.
        NutritionStore.pruneOlderThan()
        let foodAvg = NutritionStore.dailyAverage(days: 7)
        let workoutAvg = CountdownStore.weeklyRingAverage(days: 7)
        NotificationManager.shared.scheduleWeeklySummary(
            kcalAvg: foodAvg.kcal,
            proteinAvg: foodAvg.protein,
            moveAvg: workoutAvg.move,
            exerciseAvg: workoutAvg.exercise
        )

        // Refresh the cached Abs ETA so the chip on CountdownScreen stays current.
        // This is a best-effort read — we don't block on it if HealthKit is slow.
        Task {
            let weightSeries = await health.bodyMassSeries(days: 90)
            let fatSeries    = await health.bodyFatSeries(days: 90)
            let isMale       = NutritionStore.sex == .male
            let eta = AbsEstimator.estimate(
                bodyFatSeries: fatSeries,
                weightSeries: weightSeries,
                targetBodyFat: ProgressStore.targetBodyFat,
                heightCm: NutritionStore.heightCm,
                age: NutritionStore.age,
                isMale: isMale
            )
            ProgressStore.cacheETA(eta)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
