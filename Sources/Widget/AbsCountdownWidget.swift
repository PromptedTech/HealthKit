import WidgetKit
import SwiftUI

// MARK: - Timeline

struct AbsEntry: TimelineEntry {
    let date: Date
    let count: Int
    let startCount: Int
    let ring: RingData

    var progress: Double {
        let start = max(startCount, 1)
        return min(1, max(0, Double(start - count) / Double(start)))
    }

    static let sample = AbsEntry(date: Date(), count: 62, startCount: 62, ring: .sample)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AbsEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (AbsEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AbsEntry>) -> Void) {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let refresh = calendar.date(byAdding: .minute, value: 35, to: tomorrow) ?? tomorrow
        completion(Timeline(entries: [currentEntry()], policy: .after(refresh)))
    }

    private func currentEntry() -> AbsEntry {
        AbsEntry(
            date: Date(),
            count: CountdownStore.currentCount,
            startCount: CountdownStore.startCount,
            ring: CountdownStore.todayRing
        )
    }
}

// MARK: - Views

struct AbsCountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: AbsEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumBody
        default:
            smallBody
        }
    }

    // mascot image name based on ring status
    private var mascotName: String { entry.ring.bothClosed ? "mascot_done" : "mascot_idle" }

    private var mascotImage: Image? {
        guard let img = UIImage(named: mascotName) else { return nil }
        return Image(uiImage: img)
    }

    // MARK: Small widget
    // Layout: counter + rings top row, mascot + metrics bottom
    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: big number left, rings right
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(entry.count)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                    Text("days to go")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 4)
                ActivityRingsView(ring: entry.ring, lineWidth: 8, spacing: 3)
                    .frame(width: 46, height: 46)
            }

            Spacer(minLength: 6)

            // Bottom: mascot + metrics side by side
            HStack(alignment: .bottom, spacing: 8) {
                if let img = mascotImage {
                    img.resizable().scaledToFit()
                        .frame(width: 34, height: 34)
                }
                VStack(alignment: .leading, spacing: 4) {
                    metricLine("Move", Int(entry.ring.moveCurrent), entry.ring.moveGoal, "CAL", ActivityRingsView.moveColors)
                    metricLine("Exercise", Int(entry.ring.exerciseCurrent), entry.ring.exerciseGoal, "MIN", ActivityRingsView.exerciseColors)
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) { Color.black }
        .widgetURL(URL(string: "abscountdown://open"))
    }

    // MARK: Medium widget
    // Layout: [left col: mascot + rings] | [right col: counter + metrics]
    private var mediumBody: some View {
        HStack(alignment: .center, spacing: 16) {

            // Left column — mascot stacked above rings, fixed width
            VStack(spacing: 6) {
                if let img = mascotImage {
                    img.resizable().scaledToFit()
                        .frame(width: 52, height: 52)
                }
                ActivityRingsView(ring: entry.ring, lineWidth: 11, spacing: 4)
                    .frame(width: 68, height: 68)
            }
            .frame(width: 72)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 4)

            // Right column — counter + metrics, gets all remaining space
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(entry.count)")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Text("days\nto go")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    metricRow("Move", Int(entry.ring.moveCurrent), entry.ring.moveGoal, "CAL", ActivityRingsView.moveColors)
                    metricRow("Exercise", Int(entry.ring.exerciseCurrent), entry.ring.exerciseGoal, "MIN", ActivityRingsView.exerciseColors)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(for: .widget) { Color.black }
        .widgetURL(URL(string: "abscountdown://open"))
    }

    private func metricRow(_ title: String, _ value: Int, _ goal: Double, _ unit: String, _ colors: [Color]) -> some View {
        HStack(spacing: 6) {
            Circle().fill(colors[0]).frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Spacer(minLength: 4)
            Text(goal > 0 ? "\(value)/\(Int(goal)) \(unit)" : "-- \(unit)")
                .font(.caption.weight(.bold))
                .foregroundStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
        }
    }

    private func metricLine(_ title: String, _ value: Int, _ goal: Double, _ unit: String, _ colors: [Color]) -> some View {
        HStack(spacing: 5) {
            Circle().fill(colors[0]).frame(width: 6, height: 6)
            Text(goal > 0 ? "\(value)/\(Int(goal)) \(unit)" : "-- \(unit)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Widget

struct AbsCountdownWidget: Widget {
    let kind = "AbsCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AbsCountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Abs Countdown")
        .description("Days until abs, plus today's activity rings.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    AbsCountdownWidget()
} timeline: {
    AbsEntry.sample
}

#Preview(as: .systemMedium) {
    AbsCountdownWidget()
} timeline: {
    AbsEntry.sample
}
