import Foundation

/// Bridges `NutritionStore` to the SwiftUI nutrition screen.
@MainActor
final class NutritionViewModel: ObservableObject {

    @Published var todayEntries: [FoodEntry] = []
    @Published var todayKcal: Double = 0
    @Published var todayProtein: Double = 0

    @Published var calorieTarget: Double = 0
    @Published var proteinTarget: Double = 0
    @Published var needsBodyStats: Bool = false

    @Published var avgKcal: Double = 0
    @Published var avgProtein: Double = 0
    @Published var loggedDays: Int = 0
    @Published var kcalSeries: [(date: Date, kcal: Double)] = []

    init() { refresh() }

    func refresh() {
        let today = Date()
        todayEntries = NutritionStore.entries(on: today)
        let totals = NutritionStore.totals(on: today)
        todayKcal = totals.kcal
        todayProtein = totals.protein

        calorieTarget = NutritionStore.calorieTarget
        proteinTarget = NutritionStore.proteinTarget
        needsBodyStats = NutritionStore.needsBodyStats

        let avg = NutritionStore.dailyAverage(days: 7)
        avgKcal = avg.kcal
        avgProtein = avg.protein
        loggedDays = avg.loggedDays
        kcalSeries = NutritionStore.dailyKcalSeries(days: 7)
    }

    // MARK: - Derived display helpers

    /// Calories remaining under target (negative = over).
    var caloriesRemaining: Double { calorieTarget - todayKcal }

    var calorieFraction: Double {
        guard calorieTarget > 0 else { return 0 }
        return todayKcal / calorieTarget
    }

    var proteinFraction: Double {
        guard proteinTarget > 0 else { return 0 }
        return min(1, todayProtein / proteinTarget)
    }

    var proteinGoalHit: Bool { proteinTarget > 0 && todayProtein >= proteinTarget }
    var overCalories: Bool { calorieTarget > 0 && todayKcal > calorieTarget }

    /// Last few distinct foods logged (for the add-sheet "recents" row).
    func recentFoods(limit: Int = 8) -> [FoodEntry] {
        var seen = Set<String>()
        var result: [FoodEntry] = []
        for entry in NutritionStore.foodLog.sorted(by: { $0.date > $1.date }) {
            if seen.insert(entry.name).inserted {
                result.append(entry)
                if result.count >= limit { break }
            }
        }
        return result
    }

    // MARK: - Mutations

    func log(item: FoodItem, servings: Double) {
        let entry = FoodEntry(
            name: item.name,
            kcal: item.kcal,
            protein: item.protein,
            servings: servings,
            date: Date()
        )
        NutritionStore.addEntry(entry)
        refresh()
    }

    func relog(_ entry: FoodEntry, servings: Double) {
        let copy = FoodEntry(
            name: entry.name,
            kcal: entry.kcal,
            protein: entry.protein,
            servings: servings,
            date: Date()
        )
        NutritionStore.addEntry(copy)
        refresh()
    }

    func remove(_ entry: FoodEntry) {
        NutritionStore.removeEntry(id: entry.id)
        refresh()
    }
}
