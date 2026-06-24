import GameKit
import UIKit

@MainActor
final class GameCenterManager: NSObject {

    static let shared = GameCenterManager()

    // Leaderboard IDs — must be configured in App Store Connect under this bundle ID.
    static let bestStreakLeaderboard = "com.nakul.abscountdown.beststreak"
    static let goodDaysLeaderboard   = "com.nakul.abscountdown.gooddays"

    private(set) var isAuthenticated = false

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
            guard let self else { return }
            if let vc {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.keyWindow?.rootViewController?
                    .present(vc, animated: true)
            }
            self.isAuthenticated = error == nil && GKLocalPlayer.local.isAuthenticated
            if self.isAuthenticated { self.report() }
        }
    }

    func report() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        submit(CountdownStore.bestStreak,    to: Self.bestStreakLeaderboard)
        submit(CountdownStore.totalGoodDays, to: Self.goodDaysLeaderboard)
    }

    private func submit(_ score: Int, to leaderboardID: String) {
        Task {
            try? await GKLeaderboard.submitScore(
                score, context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        }
    }
}

/// SwiftUI wrapper for the Game Center leaderboard sheet.
import SwiftUI

struct GameCenterView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterView
        init(_ parent: GameCenterView) { self.parent = parent }
        func gameCenterViewControllerDidFinish(_ vc: GKGameCenterViewController) {
            parent.dismiss()
        }
    }
}
