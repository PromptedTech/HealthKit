import Foundation

/// Bridges the shared `CountdownStore` to SwiftUI views.
@MainActor
final class CountdownViewModel: ObservableObject {

    @Published var count: Int = CountdownStore.currentCount
    @Published var startCount: Int = CountdownStore.startCount
    @Published var ring: RingData = CountdownStore.todayRing
    @Published var penalties: [Date] = CountdownStore.manualPenalties
    @Published var isEvaluating = false

    // Streak & stats
    @Published var currentStreak: Int = CountdownStore.currentStreak
    @Published var bestStreak: Int = CountdownStore.bestStreak
    @Published var totalGoodDays: Int = CountdownStore.totalGoodDays
    @Published var totalBadDays: Int = CountdownStore.totalBadDays
    @Published var history: [(date: Date, status: DayStatus)] = CountdownStore.recentHistory()

    // Weekly workout averages
    @Published var weeklyMove: Double = CountdownStore.weeklyRingAverage().move
    @Published var weeklyExercise: Double = CountdownStore.weeklyRingAverage().exercise

    var progress: Double { CountdownStore.progress }
    var todayOnTrack: Bool { ring.bothClosed }
    var netDaysSaved: Int { CountdownStore.netDaysSaved }
    var todayQuote: String { Quotes.today }

    func refresh() {
        count = CountdownStore.currentCount
        startCount = CountdownStore.startCount
        ring = CountdownStore.todayRing
        penalties = CountdownStore.manualPenalties
        currentStreak = CountdownStore.currentStreak
        bestStreak = CountdownStore.bestStreak
        totalGoodDays = CountdownStore.totalGoodDays
        totalBadDays = CountdownStore.totalBadDays
        history = CountdownStore.recentHistory()
        let weekly = CountdownStore.weeklyRingAverage()
        weeklyMove = weekly.move
        weeklyExercise = weekly.exercise
    }

    func requestAuthAndEvaluate() async {
        isEvaluating = true
        await HealthKitManager.shared.requestAuthorization()
        await NotificationManager.shared.requestAuthorization()
        await EvaluationEngine.shared.runCatchUp()
        refresh()
        isEvaluating = false
    }

    func evaluateNow() async {
        isEvaluating = true
        await EvaluationEngine.shared.runCatchUp()
        refresh()
        isEvaluating = false
    }

    func addManualPenalty() {
        CountdownStore.applyManualPenalty()
        refresh()
    }

    func addManualCredit() {
        CountdownStore.applyManualCredit()
        refresh()
    }

    func reset(to value: Int) {
        CountdownStore.reset(to: value)
        refresh()
    }
}
