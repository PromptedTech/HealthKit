import SwiftUI

extension AchievementKind {
    var badgeColor: Color {
        switch self {
        case .firstGoodDay: return .green
        case .streak7:      return .orange
        case .streak14:     return .yellow
        case .streak30:     return .mint
        case .streak60:     return .purple
        case .goodDays50:   return .blue
        case .goodDays100:  return Color(red: 1, green: 0.84, blue: 0)
        case .firstFreeze:  return .cyan
        case .halfway:      return .mint
        case .absReached:   return Color(red: 1, green: 0.84, blue: 0)
        }
    }
}

struct AchievementsSheet: View {
    let unlocked: Set<AchievementKind>

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AchievementKind.allCases, id: \.self) { kind in
                            BadgeCell(kind: kind, isUnlocked: unlocked.contains(kind))
                        }
                    }
                    .padding()

                    Text("\(unlocked.count) / \(AchievementKind.allCases.count) unlocked")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }
}

private struct BadgeCell: View {
    let kind: AchievementKind
    let isUnlocked: Bool

    private var tint: Color { isUnlocked ? kind.badgeColor : .white.opacity(0.18) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 62, height: 62)
                    .overlay(Circle().strokeBorder(tint.opacity(isUnlocked ? 0.35 : 0.1), lineWidth: 1.5))

                Image(systemName: isUnlocked ? kind.icon : "lock.fill")
                    .font(.system(size: isUnlocked ? 26 : 20, weight: .semibold))
                    .foregroundStyle(tint)
            }

            Text(kind.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isUnlocked ? .white : .white.opacity(0.28))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isUnlocked ? 0.07 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(tint.opacity(isUnlocked ? 0.18 : 0.06), lineWidth: 1)
                )
        )
    }
}

/// Compact toast shown briefly at the top of the screen when a badge unlocks.
struct AchievementToast: View {
    let kind: AchievementKind

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(kind.badgeColor.opacity(0.2)).frame(width: 40, height: 40)
                Image(systemName: kind.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(kind.badgeColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked!")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
                Text(kind.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(kind.badgeColor.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 16, y: 4)
        )
        .padding(.horizontal, 16)
    }
}
