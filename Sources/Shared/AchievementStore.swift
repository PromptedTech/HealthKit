import Foundation

enum AchievementKind: String, CaseIterable, Codable {
    case firstGoodDay
    case streak7
    case streak14
    case streak30
    case streak60
    case goodDays50
    case goodDays100
    case firstFreeze
    case halfway
    case absReached

    var title: String {
        switch self {
        case .firstGoodDay: return "First Victory"
        case .streak7:      return "On a Roll"
        case .streak14:     return "Unstoppable"
        case .streak30:     return "The Grind"
        case .streak60:     return "Iron Will"
        case .goodDays50:   return "Fifty Strong"
        case .goodDays100:  return "Century"
        case .firstFreeze:  return "Clutch Save"
        case .halfway:      return "Halfway There"
        case .absReached:   return "Mission Complete"
        }
    }

    var subtitle: String {
        switch self {
        case .firstGoodDay: return "Closed both rings for the first time"
        case .streak7:      return "7 days in a row"
        case .streak14:     return "14-day streak"
        case .streak30:     return "30-day streak"
        case .streak60:     return "60-day streak"
        case .goodDays50:   return "50 total good days"
        case .goodDays100:  return "100 total good days"
        case .firstFreeze:  return "Used a streak freeze"
        case .halfway:      return "50% of countdown complete"
        case .absReached:   return "Reached 0 — abs unlocked!"
        }
    }

    var icon: String {
        switch self {
        case .firstGoodDay: return "checkmark.circle.fill"
        case .streak7:      return "flame.fill"
        case .streak14:     return "bolt.fill"
        case .streak30:     return "star.fill"
        case .streak60:     return "trophy.fill"
        case .goodDays50:   return "medal.fill"
        case .goodDays100:  return "rosette"
        case .firstFreeze:  return "snowflake"
        case .halfway:      return "chart.bar.fill"
        case .absReached:   return "sparkles"
        }
    }
}

enum AchievementStore {

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: CountdownStore.appGroup) ?? .standard
    }

    private enum Keys {
        static let unlocked = "unlockedAchievements"
        static let pending  = "pendingAchievements"
    }

    static var unlocked: Set<AchievementKind> {
        let raw = defaults.stringArray(forKey: Keys.unlocked) ?? []
        return Set(raw.compactMap { AchievementKind(rawValue: $0) })
    }

    @discardableResult
    static func unlock(_ kind: AchievementKind) -> Bool {
        var current = unlocked
        guard !current.contains(kind) else { return false }
        current.insert(kind)
        defaults.set(current.map { $0.rawValue }, forKey: Keys.unlocked)
        return true
    }

    static func isUnlocked(_ kind: AchievementKind) -> Bool {
        unlocked.contains(kind)
    }

    static func evaluate(
        streak: Int,
        totalGoodDays: Int,
        progress: Double,
        currentCount: Int,
        usedFreeze: Bool
    ) -> [AchievementKind] {
        var fresh: [AchievementKind] = []

        func check(_ kind: AchievementKind, _ condition: Bool) {
            if condition, unlock(kind) { fresh.append(kind) }
        }

        check(.firstGoodDay, totalGoodDays >= 1)
        check(.streak7,      streak >= 7)
        check(.streak14,     streak >= 14)
        check(.streak30,     streak >= 30)
        check(.streak60,     streak >= 60)
        check(.goodDays50,   totalGoodDays >= 50)
        check(.goodDays100,  totalGoodDays >= 100)
        check(.halfway,      progress >= 0.5)
        check(.absReached,   currentCount == 0)
        check(.firstFreeze,  usedFreeze)

        return fresh
    }

    static func enqueuePending(_ kinds: [AchievementKind]) {
        guard !kinds.isEmpty else { return }
        var pending = defaults.stringArray(forKey: Keys.pending) ?? []
        pending.append(contentsOf: kinds.map { $0.rawValue })
        defaults.set(pending, forKey: Keys.pending)
    }

    static func dequeuePending() -> [AchievementKind] {
        let raw = defaults.stringArray(forKey: Keys.pending) ?? []
        if !raw.isEmpty { defaults.removeObject(forKey: Keys.pending) }
        return raw.compactMap { AchievementKind(rawValue: $0) }
    }
}
