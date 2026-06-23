import SwiftUI
import BackgroundTasks

@main
struct AbsCountdownApp: App {

    @Environment(\.scenePhase) private var scenePhase

    static let bgTaskID = "com.nakul.abscountdown.dailyeval"

    init() {
        CountdownStore.bootstrapIfNeeded()
        Self.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { _ in
                    // Tapped the widget — force a fresh evaluation.
                    Task { await EvaluationEngine.shared.runCatchUp() }
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // Belt-and-suspenders: always reconcile whenever the app comes forward.
                Task { await EvaluationEngine.shared.runCatchUp() }
            case .background:
                Self.scheduleBackgroundTask()
            default:
                break
            }
        }
    }

    // MARK: - Background refresh

    private static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: bgTaskID,
            using: nil
        ) { task in
            scheduleBackgroundTask() // chain the next run
            let work = Task {
                await EvaluationEngine.shared.runCatchUp()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    private static func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: bgTaskID)
        // Aim for shortly after the next midnight so a full day has been recorded.
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        request.earliestBeginDate = calendar.date(byAdding: .minute, value: 30, to: startOfTomorrow)
        try? BGTaskScheduler.shared.submit(request)
    }
}
