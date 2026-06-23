import Foundation
import WidgetKit

// MARK: - Models

/// One logged food item for a day. `kcal`/`protein` are per single serving; the
/// `servings` multiplier scales them.
struct FoodEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var kcal: Double
    var protein: Double
    var servings: Double
    var date: Date

    var totalKcal: Double { kcal * servings }
    var totalProtein: Double { protein * servings }
}

enum NutritionGoalMode: String {
    case auto    // computed deficit target from body stats
    case manual  // user-entered numbers
}

enum Sex: String, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary, light, moderate, active
    var id: String { rawValue }

    var factor: Double {
        switch self {
        case .sedentary: return 1.2
        case .light:     return 1.375
        case .moderate:  return 1.55
        case .active:    return 1.725
        }
    }

    var label: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light:     return "Light"
        case .moderate:  return "Moderate"
        case .active:    return "Active"
        }
    }
}

/// Food / calorie / protein layer, backed by the same App Group as `CountdownStore`.
/// Kept separate from the countdown so logging food never touches the day count.
enum NutritionStore {

    static let appGroup = "group.com.nakul.abscountdown"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private enum Keys {
        static let foodLog = "foodLog"            // JSON [FoodEntry]
        static let goalMode = "nutritionGoalMode"
        static let weightKg = "bodyWeightKg"
        static let heightCm = "bodyHeightCm"
        static let age = "bodyAge"
        static let sex = "bodySex"
        static let activityLevel = "activityLevel"
        static let deficitPercent = "deficitPercent"
        static let manualCalorieGoal = "manualCalorieGoal"
        static let manualProteinGoal = "manualProteinGoal"
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func dayKey(_ date: Date) -> String {
        dayKeyFormatter.string(from: Calendar.current.startOfDay(for: date))
    }

    // MARK: - Food log

    static var foodLog: [FoodEntry] {
        get {
            guard let data = defaults.data(forKey: Keys.foodLog),
                  let entries = try? JSONDecoder().decode([FoodEntry].self, from: data)
            else { return [] }
            return entries
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.foodLog)
            }
            reloadWidgets()
        }
    }

    static func addEntry(_ entry: FoodEntry) {
        var log = foodLog
        log.append(entry)
        foodLog = log
    }

    static func removeEntry(id: UUID) {
        foodLog = foodLog.filter { $0.id != id }
    }

    /// Entries logged on the given calendar day, newest first.
    static func entries(on date: Date) -> [FoodEntry] {
        let key = dayKey(date)
        return foodLog.filter { dayKey($0.date) == key }.sorted { $0.date > $1.date }
    }

    /// Drop entries older than `days` to keep storage small.
    static func pruneOlderThan(days: Int = 120) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        let kept = foodLog.filter { $0.date >= cutoff }
        if kept.count != foodLog.count { foodLog = kept }
    }

    // MARK: - Rollups

    static func totals(on date: Date) -> (kcal: Double, protein: Double) {
        entries(on: date).reduce((0, 0)) { acc, e in
            (acc.0 + e.totalKcal, acc.1 + e.totalProtein)
        }
    }

    /// Average daily kcal + protein over the last `days` days **that actually have entries**,
    /// so a fresh install doesn't dilute the average with empty days.
    static func dailyAverage(days: Int = 7) -> (kcal: Double, protein: Double, loggedDays: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var kcalSum = 0.0, proteinSum = 0.0, logged = 0
        for offset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let t = totals(on: date)
            if t.kcal > 0 || t.protein > 0 {
                kcalSum += t.kcal
                proteinSum += t.protein
                logged += 1
            }
        }
        guard logged > 0 else { return (0, 0, 0) }
        return (kcalSum / Double(logged), proteinSum / Double(logged), logged)
    }

    /// Per-day kcal totals over the last `days` days, oldest first (for the trend bars).
    static func dailyKcalSeries(days: Int = 7) -> [(date: Date, kcal: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            return (date, totals(on: date).kcal)
        }
    }

    // MARK: - Goal configuration

    static var goalMode: NutritionGoalMode {
        get { NutritionGoalMode(rawValue: defaults.string(forKey: Keys.goalMode) ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: Keys.goalMode); reloadWidgets() }
    }

    static var weightKg: Double {
        get { defaults.double(forKey: Keys.weightKg) }
        set { defaults.set(newValue, forKey: Keys.weightKg); reloadWidgets() }
    }

    static var heightCm: Double {
        get { defaults.double(forKey: Keys.heightCm) }
        set { defaults.set(newValue, forKey: Keys.heightCm); reloadWidgets() }
    }

    static var age: Int {
        get { defaults.integer(forKey: Keys.age) }
        set { defaults.set(newValue, forKey: Keys.age); reloadWidgets() }
    }

    static var sex: Sex {
        get { Sex(rawValue: defaults.string(forKey: Keys.sex) ?? "") ?? .male }
        set { defaults.set(newValue.rawValue, forKey: Keys.sex); reloadWidgets() }
    }

    static var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: defaults.string(forKey: Keys.activityLevel) ?? "") ?? .moderate }
        set { defaults.set(newValue.rawValue, forKey: Keys.activityLevel); reloadWidgets() }
    }

    static var deficitPercent: Double {
        get {
            let v = defaults.double(forKey: Keys.deficitPercent)
            return v == 0 ? 20 : v
        }
        set { defaults.set(newValue, forKey: Keys.deficitPercent); reloadWidgets() }
    }

    static var manualCalorieGoal: Double {
        get {
            let v = defaults.double(forKey: Keys.manualCalorieGoal)
            return v == 0 ? 1800 : v
        }
        set { defaults.set(newValue, forKey: Keys.manualCalorieGoal); reloadWidgets() }
    }

    static var manualProteinGoal: Double {
        get {
            let v = defaults.double(forKey: Keys.manualProteinGoal)
            return v == 0 ? 140 : v
        }
        set { defaults.set(newValue, forKey: Keys.manualProteinGoal); reloadWidgets() }
    }

    /// True only when the auto-mode body stats are filled in enough to compute a target.
    static var hasBodyStats: Bool {
        weightKg > 0 && heightCm > 0 && age > 0
    }

    // MARK: - Computed targets (single source of truth for UI + notifications)

    /// Mifflin–St Jeor maintenance calories, or 0 when stats are missing.
    static var maintenanceCalories: Double {
        guard hasBodyStats else { return 0 }
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + (sex == .male ? 5 : -161)
        return bmr * activityLevel.factor
    }

    /// Daily calorie target. Auto = maintenance − deficit (safety-floored); Manual = user value.
    static var calorieTarget: Double {
        switch goalMode {
        case .manual:
            return manualCalorieGoal
        case .auto:
            guard hasBodyStats else { return 0 }
            let target = maintenanceCalories * (1 - deficitPercent / 100)
            let floor = sex == .male ? 1500.0 : 1200.0
            return (max(floor, target)).rounded()
        }
    }

    /// Daily protein target in grams. Auto = ~1.8 g/kg; Manual = user value.
    static var proteinTarget: Double {
        switch goalMode {
        case .manual:
            return manualProteinGoal
        case .auto:
            guard weightKg > 0 else { return 0 }
            return (weightKg * 1.8).rounded()
        }
    }

    /// True when Auto is selected but we can't compute a target yet.
    static var needsBodyStats: Bool {
        goalMode == .auto && !hasBodyStats
    }

    private static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
