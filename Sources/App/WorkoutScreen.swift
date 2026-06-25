import SwiftUI
import HealthKit

struct WorkoutScreen: View {
    @State private var workouts: [HKWorkout] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.mint)
                } else if workouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.mint)
        .preferredColorScheme(.dark)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = workouts.isEmpty
        workouts = await HealthKitManager.shared.recentWorkouts()
        isLoading = false
    }

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(workouts, id: \.uuid) { workout in
                    WorkoutRow(workout: workout)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "applewatch")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.15))
            Text("No workouts found")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Complete a workout on your Apple Watch and it will appear here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Workout row

private struct WorkoutRow: View {
    let workout: HKWorkout

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: workout.workoutActivityType.displayIcon)
                .font(.title2)
                .foregroundStyle(.mint)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(workout.workoutActivityType.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(workout.startDate, style: .date)
                    if let stats = statsText {
                        Text("·")
                        Text(stats)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Text(durationText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(14)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var durationText: String {
        let secs = Int(workout.duration)
        let m = secs / 60
        let s = secs % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }

    private var statsText: String? {
        let kcal = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?.doubleValue(for: .kilocalorie())

        let walkRunDist = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?
            .sumQuantity()?.doubleValue(for: .meter())
        let cycleDist = workout.statistics(for: HKQuantityType(.distanceCycling))?
            .sumQuantity()?.doubleValue(for: .meter())
        let kmRaw = walkRunDist ?? cycleDist
        let km = kmRaw.map { $0 / 1000 }

        if let km, let kcal {
            return String(format: "%.2f km · %.0f kcal", km, kcal)
        } else if let km {
            return String(format: "%.2f km", km)
        } else if let kcal {
            return String(format: "%.0f kcal", kcal)
        }
        return nil
    }
}

// MARK: - HKWorkoutActivityType display helpers

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running:                        return "Run"
        case .cycling:                        return "Cycling"
        case .swimming:                       return "Swim"
        case .walking:                        return "Walk"
        case .hiking:                         return "Hike"
        case .yoga:                           return "Yoga"
        case .traditionalStrengthTraining,
             .functionalStrengthTraining:     return "Strength"
        case .highIntensityIntervalTraining:  return "HIIT"
        case .elliptical:                     return "Elliptical"
        case .rowing:                         return "Rowing"
        case .crossTraining:                  return "Cross Training"
        case .mindAndBody:                    return "Mind & Body"
        case .pilates:                        return "Pilates"
        case .dance:                          return "Dance"
        case .soccer:                         return "Soccer"
        case .basketball:                     return "Basketball"
        case .cooldown:                       return "Cooldown"
        default:                              return "Workout"
        }
    }

    var displayIcon: String {
        switch self {
        case .running:                        return "figure.run"
        case .cycling:                        return "figure.outdoor.cycle"
        case .swimming:                       return "figure.pool.swim"
        case .walking:                        return "figure.walk"
        case .hiking:                         return "figure.hiking"
        case .yoga:                           return "figure.yoga"
        case .traditionalStrengthTraining,
             .functionalStrengthTraining:     return "dumbbell.fill"
        case .highIntensityIntervalTraining:  return "bolt.fill"
        case .elliptical:                     return "figure.elliptical"
        case .rowing:                         return "figure.rowing"
        case .crossTraining:                  return "figure.cross.training"
        case .mindAndBody:                    return "brain.head.profile"
        case .pilates:                        return "figure.pilates"
        case .dance:                          return "figure.dance"
        case .cooldown:                       return "wind"
        default:                              return "heart.fill"
        }
    }
}
