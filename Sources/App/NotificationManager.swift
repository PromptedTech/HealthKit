import Foundation
import UserNotifications

/// Schedules a single local "rings still open" nudge at 7 PM on days the user hasn't
/// closed both rings yet. Best-effort: the decision is made from the last `runCatchUp`,
/// so it reflects ring state as of the most recent app/background run.
final class NotificationManager {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let reminderID = "evening-reminder"
    private let reminderHour = 19   // 7 PM
    private let weekendID = "weekend-summary"
    private let weekendHour = 19     // Sunday 7 PM

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// If rings are closed, clear any pending nudge. Otherwise, (re)schedule one for
    /// 7 PM today — but only if 7 PM hasn't already passed.
    func syncReminder(ringsClosed: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
        guard !ringsClosed else { return }

        let calendar = Calendar.current
        let now = Date()
        guard let fireDate = calendar.date(
            bySettingHour: reminderHour, minute: 0, second: 0, of: now
        ), fireDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rings still open ⭕️"
        content.body = "Close your Move + Exercise rings to drop a day off your countdown."
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        center.add(request)
    }

    /// (Re)schedule the weekend recap for the upcoming Sunday at 7 PM with the latest
    /// week-to-date averages baked into the body. Re-armed on each run so the numbers stay
    /// current; best-effort, like `syncReminder`.
    func scheduleWeeklySummary(kcalAvg: Double, proteinAvg: Double,
                               moveAvg: Double, exerciseAvg: Double) {
        center.removePendingNotificationRequests(withIdentifiers: [weekendID])

        let calendar = Calendar.current
        let now = Date()
        // Find the next Sunday (weekday == 1) at `weekendHour`:00 in the future.
        var comps = DateComponents()
        comps.weekday = 1
        comps.hour = weekendHour
        comps.minute = 0
        guard let fireDate = calendar.nextDate(
            after: now, matching: comps, matchingPolicy: .nextTime
        ) else { return }

        var parts: [String] = []
        if kcalAvg > 0 { parts.append("Ø \(Int(kcalAvg.rounded())) kcal") }
        if proteinAvg > 0 { parts.append("\(Int(proteinAvg.rounded())) g protein/day") }
        if moveAvg > 0 { parts.append("\(Int(moveAvg.rounded())) cal move") }
        if exerciseAvg > 0 { parts.append("\(Int(exerciseAvg.rounded())) min ex") }

        let content = UNMutableNotificationContent()
        content.title = "Your week in review 📊"
        content.body = parts.isEmpty
            ? "Start logging food and closing rings to see your weekly recap."
            : parts.joined(separator: " · ") + ". Keep cutting 🔥"
        content.sound = .default

        let triggerComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        let request = UNNotificationRequest(identifier: weekendID, content: content, trigger: trigger)
        center.add(request)
    }
}
