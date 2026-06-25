import SwiftUI
import HealthKit

@MainActor
final class WorkoutLogger: ObservableObject {

    // MARK: - Published state

    @Published var isActive = false
    @Published var isStrength = true
    @Published var isSaving = false

    // Strength
    @Published var exercises: [Exercise] = []

    // Cardio
    @Published var cardioType: WorkoutKind.CardioType = .running
    @Published var distanceKm: Double = 0
    @Published var caloriesBurned: Double = 0

    // Session timing
    @Published var elapsedSecs: Int = 0

    // Rest timer
    @Published var restSecondsLeft: Int = 0
    @Published var restTotalSecs: Int = 0
    @Published var restTimerActive = false

    private var startTime: Date?
    private var elapsedTimer: Timer?
    private var restTimer: Timer?

    // MARK: - Start

    func startStrength() {
        exercises = []
        isStrength = true
        beginSession()
    }

    func startCardio(_ type: WorkoutKind.CardioType) {
        cardioType = type
        distanceKm = 0
        caloriesBurned = 0
        isStrength = false
        beginSession()
    }

    private func beginSession() {
        startTime = Date()
        elapsedSecs = 0
        isActive = true
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.elapsedSecs += 1 }
        }
    }

    // MARK: - Finish / Cancel

    func finishSession() async {
        isSaving = true
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        stopRestTimer()

        let end = Date()
        let start = startTime ?? end.addingTimeInterval(-Double(elapsedSecs))

        if isStrength {
            let record = WorkoutRecord(
                date: start,
                kind: .strength,
                durationSecs: elapsedSecs,
                totalSets: exercises.reduce(0) { $0 + $1.sets.count },
                totalVolumeKg: exercises.reduce(0) { $0 + $1.totalVolumeKg }
            )
            WorkoutStore.add(record)
            await HealthKitManager.shared.saveWorkout(
                activityType: .traditionalStrengthTraining,
                start: start, end: end,
                totalEnergyBurned: nil, totalDistance: nil
            )
        } else {
            let record = WorkoutRecord(
                date: start,
                kind: .cardio(cardioType),
                durationSecs: elapsedSecs,
                distanceKm: distanceKm > 0 ? distanceKm : nil,
                calories: caloriesBurned > 0 ? caloriesBurned : nil
            )
            WorkoutStore.add(record)
            await HealthKitManager.shared.saveWorkout(
                activityType: cardioType.hkActivityType,
                start: start, end: end,
                totalEnergyBurned: caloriesBurned > 0 ? caloriesBurned : nil,
                totalDistance: distanceKm > 0 ? distanceKm : nil
            )
        }

        isActive = false
        isSaving = false
    }

    func cancelSession() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        stopRestTimer()
        isActive = false
        exercises = []
    }

    // MARK: - Exercise management (strength)

    func addExercise(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        exercises.append(Exercise(name: trimmed))
    }

    func appendSet(to exerciseID: UUID, reps: Int, weightKg: Double) {
        guard let idx = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[idx].sets.append(ExerciseSet(reps: reps, weightKg: weightKg))
    }

    func removeExercise(withID id: UUID) {
        exercises.removeAll { $0.id == id }
    }

    // MARK: - Rest timer

    func startRest(seconds: Int) {
        stopRestTimer()
        restTotalSecs = seconds
        restSecondsLeft = seconds
        restTimerActive = true
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.restSecondsLeft > 1 {
                    self.restSecondsLeft -= 1
                } else {
                    self.restSecondsLeft = 0
                    self.restTimerActive = false
                    self.stopRestTimer()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restSecondsLeft = 0
        restTotalSecs = 0
    }
}

// MARK: - CardioType → HKWorkoutActivityType

extension WorkoutKind.CardioType {
    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .running:    return .running
        case .cycling:    return .cycling
        case .rowing:     return .rowing
        case .elliptical: return .elliptical
        case .hiking:     return .hiking
        case .other:      return .other
        }
    }
}
