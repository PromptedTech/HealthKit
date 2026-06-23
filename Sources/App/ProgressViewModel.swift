import SwiftUI

@MainActor
final class ProgressViewModel: ObservableObject {

    // MARK: - Published state

    @Published var weightSeries: [(date: Date, kg: Double)] = []
    @Published var bodyFatSeries: [(date: Date, pct: Double)] = []
    @Published var bodyFatIsEstimated = false

    @Published var currentWeight: Double? = nil
    @Published var currentBodyFat: Double? = nil   // percent

    @Published var targetBodyFat: Double = 12.0
    @Published var etaDate: Date? = nil
    @Published var weeksRemaining: Double = 0
    @Published var weeklyRateKg: Double = 0
    @Published var etaState: ETAState = .needMoreData

    @Published var allPhotos: [ProgressPhoto] = []

    // MARK: - Refresh

    private let health = HealthKitManager.shared

    func refresh() async {
        // Pull series from HealthKit
        let rawWeight = await health.bodyMassSeries(days: 90)
        let rawFat    = await health.bodyFatSeries(days: 90)

        weightSeries  = rawWeight
        bodyFatSeries = rawFat
        currentWeight = rawWeight.last?.kg
        currentBodyFat = rawFat.last?.pct

        // Load target from store, seeding a sex-appropriate default on first run
        let storedTarget = ProgressStore.targetBodyFat
        targetBodyFat = storedTarget

        // Run estimator
        let isMale = NutritionStore.sex == .male
        let eta = AbsEstimator.estimate(
            bodyFatSeries: rawFat,
            weightSeries: rawWeight,
            targetBodyFat: targetBodyFat,
            heightCm: NutritionStore.heightCm,
            age: NutritionStore.age,
            isMale: isMale
        )

        // Detect if we used estimated BF% (no real samples)
        bodyFatIsEstimated = rawFat.count < 2 && rawWeight.count >= 2

        etaState = eta.state
        weeklyRateKg = eta.weeklyRateKg
        if case .onTrack(let date, let weeks) = eta.state {
            etaDate = date
            weeksRemaining = weeks
        } else {
            etaDate = nil
            weeksRemaining = 0
        }

        // Cache for widget / ETA chip
        ProgressStore.cacheETA(eta)

        // Photos
        allPhotos = ProgressStore.allPhotos
    }

    // MARK: - Logging

    func logWeight(_ kg: Double) async {
        await health.saveBodyMass(kg)
        await refresh()
    }

    func logBodyFat(_ pct: Double) async {
        await health.saveBodyFat(pct)
        await refresh()
    }

    // MARK: - Target

    func setTarget(_ pct: Double) {
        ProgressStore.targetBodyFat = pct
        targetBodyFat = pct
    }

    // MARK: - Photos

    func addPhoto(_ image: UIImage, pose: Pose) {
        _ = ProgressStore.addPhoto(image, pose: pose, weightKg: currentWeight, bodyFat: currentBodyFat)
        allPhotos = ProgressStore.allPhotos
    }

    func deletePhoto(_ photo: ProgressPhoto) {
        ProgressStore.deletePhoto(id: photo.id)
        allPhotos = ProgressStore.allPhotos
    }

    func photos(for pose: Pose) -> [ProgressPhoto] {
        allPhotos.filter { $0.pose == pose }.sorted { $0.date < $1.date }
    }

    func comparePair(for pose: Pose) -> (first: ProgressPhoto, latest: ProgressPhoto)? {
        ProgressStore.comparePair(pose: pose)
    }

    // MARK: - Convenience

    var displayCurrentBF: String {
        if let bf = currentBodyFat { return String(format: "%.1f%%", bf) }
        return "—"
    }

    var displayCurrentWeight: String {
        if let w = currentWeight { return String(format: "%.1f kg", w) }
        return "—"
    }

    var displayWeeklyRate: String {
        guard weeklyRateKg != 0 else { return "—" }
        let sign = weeklyRateKg < 0 ? "-" : "+"
        return "\(sign)\(String(format: "%.2f", abs(weeklyRateKg))) kg/wk"
    }
}
