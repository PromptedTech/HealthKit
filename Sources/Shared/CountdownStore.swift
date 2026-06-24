import Foundation
import WidgetKit

/// Outcome of a single calendar day, used by the 7-day history strip.
enum DayStatus {
    case good    // both rings closed
    case bad     // missed / penalized
    case frozen  // streak freeze absorbed the miss
    case none    // no Watch data
}

/// What to write into dayHistory for a settled day.
enum DayOutcome {
    case good, bad, frozen
}

/// Shared data layer backed by the App Group so the app and the widget read/write
/// the same values. The "count" is a number of *good days remaining* — it is not tied
/// to the calendar. Good days (both rings closed) decrement it; missed days and manual
/// penalties increment it.
enum CountdownStore {

    /// Must match the App Group in both targets' entitlements files.
    static let appGroup = "group.com.nakul.abscountdown"

    /// The value the counter starts at, and the baseline used for the progress bar.
    static let defaultStart = 62

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private enum Keys {
        static let initialized = "initialized"
        static let currentCount = "currentCount"
        static let startCount = "startCount"
        static let lastSettledDate = "lastSettledDate"
        static let moveCurrent = "moveCurrent"
        static let moveGoal = "moveGoal"
        static let exerciseCurrent = "exerciseCurrent"
        static let exerciseGoal = "exerciseGoal"
        static let manualPenalties = "manualPenalties"
        static let manualCredits = "manualCredits"
        // Streak / stats
        static let currentStreak = "currentStreak"
        static let bestStreak = "bestStreak"
        static let totalGoodDays = "totalGoodDays"
        static let totalBadDays = "totalBadDays"
        // Day history (yyyy-MM-dd -> 1 good / -1 bad)
        static let dayHistory = "dayHistory"
        // Per-day ring snapshots (yyyy-MM-dd -> {move, moveGoal, exercise, exerciseGoal})
        static let ringHistory = "ringHistory"
        // Custom challenge goals
        static let customGoalsEnabled = "customGoalsEnabled"
        static let customMoveGoal = "customMoveGoal"
        static let customExerciseGoal = "customExerciseGoal"
        // Streak freezes
        static let streakFreezes = "streakFreezes"
        static let freezeHistory = "freezeHistory"
    }

    /// Stable day key in the device's local calendar.
    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date) -> String {
        dayKeyFormatter.string(from: Calendar.current.startOfDay(for: date))
    }

    // MARK: - Bootstrap

    static func bootstrapIfNeeded() {
        guard !defaults.bool(forKey: Keys.initialized) else { return }
        defaults.set(true, forKey: Keys.initialized)
        defaults.set(defaultStart, forKey: Keys.currentCount)
        defaults.set(defaultStart, forKey: Keys.startCount)
    }

    // MARK: - Count

    static var currentCount: Int {
        get { defaults.integer(forKey: Keys.currentCount) }
        set { defaults.set(max(0, newValue), forKey: Keys.currentCount); reloadWidgets() }
    }

    static var startCount: Int {
        get {
            let value = defaults.integer(forKey: Keys.startCount)
            return value == 0 ? defaultStart : value
        }
        set { defaults.set(newValue, forKey: Keys.startCount); reloadWidgets() }
    }

    /// The last calendar day whose outcome (+1 / -1) has been committed. Defaults to
    /// *yesterday* so a fresh install never back-penalizes earlier days, but today is
    /// immediately eligible to be credited once both rings close.
    static var lastSettledDate: Date {
        get {
            if let date = defaults.object(forKey: Keys.lastSettledDate) as? Date { return date }
            let today = Calendar.current.startOfDay(for: Date())
            return Calendar.current.date(byAdding: .day, value: -1, to: today)!
        }
        set { defaults.set(newValue, forKey: Keys.lastSettledDate) }
    }

    // MARK: - Today's rings

    static var todayRing: RingData {
        get {
            RingData(
                moveCurrent: defaults.double(forKey: Keys.moveCurrent),
                moveGoal: defaults.double(forKey: Keys.moveGoal),
                exerciseCurrent: defaults.double(forKey: Keys.exerciseCurrent),
                exerciseGoal: defaults.double(forKey: Keys.exerciseGoal)
            )
        }
        set {
            defaults.set(newValue.moveCurrent, forKey: Keys.moveCurrent)
            defaults.set(newValue.moveGoal, forKey: Keys.moveGoal)
            defaults.set(newValue.exerciseCurrent, forKey: Keys.exerciseCurrent)
            defaults.set(newValue.exerciseGoal, forKey: Keys.exerciseGoal)
            reloadWidgets()
        }
    }

    // MARK: - Manual adjustments

    static var manualPenalties: [Date] {
        get {
            let raw = defaults.array(forKey: Keys.manualPenalties) as? [Double] ?? []
            return raw.map { Date(timeIntervalSince1970: $0) }
        }
        set { defaults.set(newValue.map { $0.timeIntervalSince1970 }, forKey: Keys.manualPenalties) }
    }

    static var manualCredits: [Date] {
        get {
            let raw = defaults.array(forKey: Keys.manualCredits) as? [Double] ?? []
            return raw.map { Date(timeIntervalSince1970: $0) }
        }
        set { defaults.set(newValue.map { $0.timeIntervalSince1970 }, forKey: Keys.manualCredits) }
    }

    // MARK: - Streak & stats

    static var currentStreak: Int {
        get { defaults.integer(forKey: Keys.currentStreak) }
        set { defaults.set(max(0, newValue), forKey: Keys.currentStreak); reloadWidgets() }
    }

    static var bestStreak: Int {
        get { defaults.integer(forKey: Keys.bestStreak) }
        set { defaults.set(max(0, newValue), forKey: Keys.bestStreak) }
    }

    static var totalGoodDays: Int {
        get { defaults.integer(forKey: Keys.totalGoodDays) }
        set { defaults.set(max(0, newValue), forKey: Keys.totalGoodDays) }
    }

    static var totalBadDays: Int {
        get { defaults.integer(forKey: Keys.totalBadDays) }
        set { defaults.set(max(0, newValue), forKey: Keys.totalBadDays) }
    }

    /// Net days earned vs lost over the app's lifetime.
    static var netDaysSaved: Int { totalGoodDays - totalBadDays }

    // MARK: - Day history

    static var dayHistory: [String: Int] {
        get { defaults.dictionary(forKey: Keys.dayHistory) as? [String: Int] ?? [:] }
        set { defaults.set(newValue, forKey: Keys.dayHistory) }
    }

    /// Record a single day's outcome (idempotent per day key).
    /// Stored as: 1 = good, -1 = bad, 0 = frozen (nil key = no data).
    static func recordDay(_ date: Date, outcome: DayOutcome) {
        var history = dayHistory
        switch outcome {
        case .good:   history[dayKey(date)] = 1
        case .bad:    history[dayKey(date)] = -1
        case .frozen: history[dayKey(date)] = 0
        }
        dayHistory = history
    }

    /// Ordered statuses for the last `days` calendar days, oldest first, ending today.
    static func recentHistory(days: Int = 7) -> [(date: Date, status: DayStatus)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let history = dayHistory
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let status: DayStatus
            if let raw = history[dayKey(date)] {
                switch raw {
                case  1:  status = .good
                case -1:  status = .bad
                default:  status = .frozen
                }
            } else {
                status = .none
            }
            return (date, status)
        }
    }

    // MARK: - Ring history (per-day Move/Exercise snapshots)

    /// `yyyy-MM-dd` -> ["move", "moveGoal", "exercise", "exerciseGoal"]. Used for the
    /// weekly workout average; written from the catch-up loop as each day is settled.
    static var ringHistory: [String: [String: Double]] {
        get { defaults.dictionary(forKey: Keys.ringHistory) as? [String: [String: Double]] ?? [:] }
        set { defaults.set(newValue, forKey: Keys.ringHistory) }
    }

    /// Store one day's ring values (idempotent per day key).
    static func recordRing(_ date: Date, _ ring: RingData) {
        var history = ringHistory
        history[dayKey(date)] = [
            "move": ring.moveCurrent,
            "moveGoal": ring.moveGoal,
            "exercise": ring.exerciseCurrent,
            "exerciseGoal": ring.exerciseGoal
        ]
        ringHistory = history
    }

    /// Average Move calories + Exercise minutes over the last `days` days that have data.
    static func weeklyRingAverage(days: Int = 7) -> (move: Double, exercise: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let history = ringHistory
        var moveSum = 0.0, exerciseSum = 0.0, count = 0
        for offset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            guard let day = history[dayKey(date)] else { continue }
            moveSum += day["move"] ?? 0
            exerciseSum += day["exercise"] ?? 0
            count += 1
        }
        guard count > 0 else { return (0, 0) }
        return (moveSum / Double(count), exerciseSum / Double(count))
    }

    // MARK: - Custom challenge goals

    static var customGoalsEnabled: Bool {
        get { defaults.bool(forKey: Keys.customGoalsEnabled) }
        set { defaults.set(newValue, forKey: Keys.customGoalsEnabled); reloadWidgets() }
    }

    static var customMoveGoal: Double {
        get {
            let value = defaults.double(forKey: Keys.customMoveGoal)
            return value == 0 ? 600 : value
        }
        set { defaults.set(newValue, forKey: Keys.customMoveGoal); reloadWidgets() }
    }

    static var customExerciseGoal: Double {
        get {
            let value = defaults.double(forKey: Keys.customExerciseGoal)
            return value == 0 ? 30 : value
        }
        set { defaults.set(newValue, forKey: Keys.customExerciseGoal); reloadWidgets() }
    }

    /// When custom goals are on, swap in the harder targets so both the closed-logic
    /// and the displayed "/goal" reflect the challenge instead of the Watch's goals.
    static func applyingGoalOverrides(to ring: RingData) -> RingData {
        guard customGoalsEnabled else { return ring }
        var copy = ring
        copy.moveGoal = customMoveGoal
        copy.exerciseGoal = customExerciseGoal
        return copy
    }

    // MARK: - Derived

    static var progress: Double {
        let start = max(startCount, 1)
        return min(1, max(0, Double(start - currentCount) / Double(start)))
    }

    // MARK: - Mutators

    // MARK: - Streak freezes

    /// Available freeze tokens (capped at 3). Earned automatically every 7 consecutive good days.
    static var streakFreezes: Int {
        get { defaults.integer(forKey: Keys.streakFreezes) }
        set { defaults.set(max(0, min(3, newValue)), forKey: Keys.streakFreezes) }
    }

    static var freezeHistory: [Date] {
        get {
            (defaults.array(forKey: Keys.freezeHistory) as? [Double] ?? []).map { Date(timeIntervalSince1970: $0) }
        }
        set { defaults.set(newValue.map { $0.timeIntervalSince1970 }, forKey: Keys.freezeHistory) }
    }

    /// Consume one freeze to protect an otherwise-missed day.
    /// Returns true when a freeze was available and consumed.
    @discardableResult
    static func tryConsumeFreeze(for date: Date) -> Bool {
        guard currentStreak > 0, streakFreezes > 0 else { return false }
        streakFreezes -= 1
        var h = freezeHistory
        h.append(date)
        freezeHistory = h
        return true
    }

    // MARK: - Mutators

    static func applyGoodDay() {
        currentCount = max(0, currentCount - 1)
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
        totalGoodDays += 1
        // Award one freeze every 7-day milestone, up to a cap of 3.
        if currentStreak % 7 == 0 && streakFreezes < 3 {
            streakFreezes += 1
        }
    }

    static func applyBadDay() {
        currentCount += 1
        currentStreak = 0
        totalBadDays += 1
    }

    static func applyManualPenalty() {
        currentCount += 1
        currentStreak = 0          // a penalty day breaks the streak
        totalBadDays += 1
        manualPenalties.append(Date())
        reloadWidgets()
    }

    static func applyManualCredit() {
        currentCount = max(0, currentCount - 1)
        manualCredits.append(Date())
        reloadWidgets()
    }

    static func reset(to value: Int) {
        startCount = value
        currentCount = value
        manualPenalties = []
        manualCredits = []
        currentStreak = 0
        bestStreak = 0
        totalGoodDays = 0
        totalBadDays = 0
        dayHistory = [:]
        ringHistory = [:]
        streakFreezes = 0
        freezeHistory = []
        let today = Calendar.current.startOfDay(for: Date())
        lastSettledDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        reloadWidgets()
    }

    private static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
