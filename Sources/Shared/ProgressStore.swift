import Foundation
import UIKit
import WidgetKit

// MARK: - Models

enum Pose: String, Codable, CaseIterable, Identifiable {
    case front, side, back
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .front: return "person.fill"
        case .side:  return "person.fill.turn.right"
        case .back:  return "person.fill.turn.left"
        }
    }
}

struct ProgressPhoto: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var fileName: String       // relative to app-group container
    var pose: Pose
    var weightKg: Double?
    var bodyFat: Double?       // percent, nil if not recorded
}

// MARK: - Store

/// Persists progress-photo metadata and the cached Abs ETA.
/// Image bytes live in the App Group container directory (too large for UserDefaults).
/// Weight and body-fat samples are the HealthKit store's job.
enum ProgressStore {

    static let appGroup = "group.com.nakul.abscountdown"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    private static var photosDir: URL? {
        guard let base = containerURL else { return nil }
        let dir = base.appendingPathComponent("ProgressPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private enum Keys {
        static let photoMetadata   = "progressPhotoMetadata"
        static let targetBodyFat   = "progressTargetBodyFat"
        static let cachedETADate   = "progressCachedETADate"
        static let cachedETAWeeks  = "progressCachedETAWeeks"
        static let cachedETAState  = "progressCachedETAState"   // "onTrack"|"notLosingYet"|"needMoreData"|"alreadyThere"
    }

    // MARK: - Target body fat

    static var targetBodyFat: Double {
        get {
            let v = defaults.double(forKey: Keys.targetBodyFat)
            return v == 0 ? 12.0 : v   // 12% male default; caller should set from sex
        }
        set { defaults.set(newValue, forKey: Keys.targetBodyFat) }
    }

    // MARK: - Cached ETA (written by EvaluationEngine; read by widget/strip)

    static func cacheETA(_ eta: AbsETA) {
        defaults.set(eta.targetBodyFat, forKey: Keys.targetBodyFat)
        switch eta.state {
        case .onTrack(let date, let weeks):
            defaults.set("onTrack", forKey: Keys.cachedETAState)
            defaults.set(date, forKey: Keys.cachedETADate)
            defaults.set(weeks, forKey: Keys.cachedETAWeeks)
        case .notLosingYet:
            defaults.set("notLosingYet", forKey: Keys.cachedETAState)
        case .needMoreData:
            defaults.set("needMoreData", forKey: Keys.cachedETAState)
        case .alreadyThere:
            defaults.set("alreadyThere", forKey: Keys.cachedETAState)
        }
    }

    static var cachedETADate: Date? { defaults.object(forKey: Keys.cachedETADate) as? Date }
    static var cachedETAWeeks: Double { defaults.double(forKey: Keys.cachedETAWeeks) }
    static var cachedETAState: String { defaults.string(forKey: Keys.cachedETAState) ?? "needMoreData" }

    // MARK: - Photo metadata

    static var allPhotos: [ProgressPhoto] {
        get {
            guard let data = defaults.data(forKey: Keys.photoMetadata),
                  let items = try? JSONDecoder().decode([ProgressPhoto].self, from: data)
            else { return [] }
            return items
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.photoMetadata)
            }
        }
    }

    static func photos(pose: Pose) -> [ProgressPhoto] {
        allPhotos.filter { $0.pose == pose }.sorted { $0.date < $1.date }
    }

    /// Returns (first, latest) for a pose — the before/after pair.
    static func comparePair(pose: Pose) -> (first: ProgressPhoto, latest: ProgressPhoto)? {
        let list = photos(pose: pose)
        guard list.count >= 2, let first = list.first, let last = list.last else { return nil }
        return (first, last)
    }

    // MARK: - Photo write / delete

    static func addPhoto(_ image: UIImage, pose: Pose, weightKg: Double?, bodyFat: Double?) -> ProgressPhoto? {
        guard let dir = photosDir else { return nil }
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = dir.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: fileURL)
        } catch {
            return nil
        }
        let photo = ProgressPhoto(id: id, date: Date(), fileName: fileName, pose: pose, weightKg: weightKg, bodyFat: bodyFat)
        var list = allPhotos
        list.append(photo)
        allPhotos = list
        return photo
    }

    static func deletePhoto(id: UUID) {
        if let photo = allPhotos.first(where: { $0.id == id }),
           let dir = photosDir {
            let url = dir.appendingPathComponent(photo.fileName)
            try? FileManager.default.removeItem(at: url)
        }
        allPhotos = allPhotos.filter { $0.id != id }
    }

    static func imageFor(_ photo: ProgressPhoto) -> UIImage? {
        guard let dir = photosDir else { return nil }
        let url = dir.appendingPathComponent(photo.fileName)
        return UIImage(contentsOfFile: url.path)
    }

    static func pruneOlderThan(days: Int = 365) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        let toDelete = allPhotos.filter { $0.date < cutoff }
        toDelete.forEach { deletePhoto(id: $0.id) }
    }
}
