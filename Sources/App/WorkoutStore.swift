import Foundation

// MARK: - Workout kind

enum WorkoutKind: Codable, Equatable {
    case strength
    case cardio(CardioType)

    enum CardioType: String, Codable, CaseIterable {
        case running, cycling, rowing, elliptical, hiking, other

        var label: String {
            switch self {
            case .running:    return "Running"
            case .cycling:    return "Cycling"
            case .rowing:     return "Rowing"
            case .elliptical: return "Elliptical"
            case .hiking:     return "Hiking"
            case .other:      return "Cardio"
            }
        }

        var icon: String {
            switch self {
            case .running:    return "figure.run"
            case .cycling:    return "figure.outdoor.cycle"
            case .rowing:     return "figure.rowing"
            case .elliptical: return "figure.elliptical"
            case .hiking:     return "figure.hiking"
            case .other:      return "heart.fill"
            }
        }
    }

    var label: String {
        switch self {
        case .strength:      return "Strength"
        case .cardio(let t): return t.label
        }
    }

    var icon: String {
        switch self {
        case .strength:      return "dumbbell.fill"
        case .cardio(let t): return t.icon
        }
    }
}

// MARK: - Exercise model

struct ExerciseSet: Codable, Identifiable {
    var id: UUID = UUID()
    var reps: Int
    var weightKg: Double
}

struct Exercise: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var sets: [ExerciseSet] = []

    var totalVolumeKg: Double { sets.reduce(0) { $0 + Double($1.reps) * $1.weightKg } }
}

// MARK: - Workout record

struct WorkoutRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var kind: WorkoutKind
    var durationSecs: Int
    var totalSets: Int?
    var totalVolumeKg: Double?
    var distanceKm: Double?
    var calories: Double?

    var durationString: String {
        let m = durationSecs / 60
        let s = durationSecs % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}

// MARK: - Persistence

enum WorkoutStore {
    private static let suite = UserDefaults(suiteName: "group.com.nakul.abscountdown")!
    private enum Keys {
        static let records = "workoutRecords"
    }

    static var records: [WorkoutRecord] {
        get {
            guard let data = suite.data(forKey: Keys.records),
                  let arr = try? JSONDecoder().decode([WorkoutRecord].self, from: data)
            else { return [] }
            return arr
        }
        set {
            suite.set(try? JSONEncoder().encode(newValue), forKey: Keys.records)
        }
    }

    static func add(_ record: WorkoutRecord) {
        var all = records
        all.insert(record, at: 0)
        if all.count > 50 { all = Array(all.prefix(50)) }
        records = all
    }

    static func delete(id: UUID) {
        records = records.filter { $0.id != id }
    }
}
