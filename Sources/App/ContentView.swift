import SwiftUI

/// Root: three tabs — earned countdown, nutrition, and progress.
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CountdownScreen(selectedTab: $selectedTab)
                .tabItem { Label("Countdown", systemImage: "flame.fill") }
                .tag(0)

            NutritionScreen()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
                .tag(1)

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            WorkoutScreen()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
                .tag(3)
        }
        .tint(.mint)
        .preferredColorScheme(.dark)
    }
}

struct CountdownScreen: View {

    @Binding var selectedTab: Int

    @StateObject private var model = CountdownViewModel()
    @StateObject private var nutrition = NutritionViewModel()
    @State private var etaState: String = ProgressStore.cachedETAState
    @State private var etaDate: Date? = ProgressStore.cachedETADate
    @State private var etaWeeks: Double = ProgressStore.cachedETAWeeks
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var showGameCenter = false
    @State private var shareItem: ShareableImage? = nil
    @State private var hasCelebrated = false
    @State private var pulse = false
    @State private var historyAppeared = false
    @State private var toastQueue: [AchievementKind] = []
    @State private var showToast = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        nutritionAveragesStrip
                        absETAChip
                        countdownHero
                        activityCard
                        weeklyWorkoutCard
                        quoteCard
                        historyStrip
                        statsCard
                        penaltyButton
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                if model.count == 0 && hasCelebrated {
                    ConfettiView()
                        .transition(.opacity)
                        .ignoresSafeArea()
                }

                // Achievement toast
                if showToast, let kind = toastQueue.first {
                    AchievementToast(kind: kind)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationTitle("Abs Countdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    shareButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(.white)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(model: model)
                    .onDisappear { nutrition.refresh() }
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsSheet(unlocked: model.unlockedAchievements)
            }
            .sheet(isPresented: $showGameCenter) {
                GameCenterView()
            }
            .task { await model.requestAuthAndEvaluate() }
            .refreshable { await model.evaluateNow() }
            .onChange(of: model.count) { _, newValue in
                hasCelebrated = (newValue == 0)
                refreshShareItem()
            }
            .onChange(of: model.pendingAchievements) { _, newValue in
                guard !newValue.isEmpty else { return }
                toastQueue = newValue
                model.pendingAchievements = []
                showNextToast()
            }
            .onChange(of: model.isEvaluating) { _, evaluating in
                if !evaluating { refreshShareItem() }
            }
            .onAppear {
                hasCelebrated = (model.count == 0)
                nutrition.refresh()
                etaState = ProgressStore.cachedETAState
                etaDate  = ProgressStore.cachedETADate
                etaWeeks = ProgressStore.cachedETAWeeks
                refreshShareItem()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Share button

    /// Pre-render the progress card whenever key stats change.
    private func refreshShareItem() {
        guard let img = ShareCardView.render(
            count: model.count,
            streak: model.currentStreak,
            progress: model.progress
        ) else { return }
        shareItem = ShareableImage(uiImage: img)
    }

    @ViewBuilder
    private var shareButton: some View {
        if let item = shareItem {
            ShareLink(
                item: item,
                preview: SharePreview(
                    "My AbsCountdown Progress",
                    image: Image(uiImage: item.uiImage)
                )
            ) {
                Image(systemName: "square.and.arrow.up")
            }
            .tint(.white)
        } else {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    // MARK: - Toast sequencing

    private func showNextToast() {
        guard !toastQueue.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.3)) { showToast = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                toastQueue.removeFirst()
                if !toastQueue.isEmpty { showNextToast() }
            }
        }
    }

    // MARK: - Nutrition averages strip

    private var nutritionAveragesStrip: some View {
        Button { selectedTab = 1 } label: {
            HStack(spacing: 14) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.mint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.mint.opacity(0.15)))

                if nutrition.loggedDays > 0 {
                    HStack(spacing: 6) {
                        Text("Ø \(Int(nutrition.avgKcal.rounded()))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("kcal").font(.caption2).foregroundStyle(.white.opacity(0.5))
                        Text("·").foregroundStyle(.white.opacity(0.3))
                        Text("\(Int(nutrition.avgProtein.rounded()))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("g protein / day").font(.caption2).foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    Text("Log today's food →")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - Abs ETA chip

    private var absETAChip: some View {
        Button { selectedTab = 2 } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.orange.opacity(0.15)))

                Group {
                    switch etaState {
                    case "onTrack":
                        HStack(spacing: 6) {
                            if let d = etaDate {
                                let fmt: DateFormatter = {
                                    let f = DateFormatter(); f.dateFormat = "MMM d"; return f
                                }()
                                Text("Abs by \(fmt.string(from: d))")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("· \(Int(etaWeeks.rounded()))w away")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            } else {
                                Text("On track")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    case "alreadyThere":
                        Text("You've hit your body-fat target 🎉")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.mint)
                    case "notLosingYet":
                        Text("Not in a deficit yet — check Progress →")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange.opacity(0.9))
                    default:
                        Text("Log weight to project Abs ETA →")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
        }
        .buttonStyle(PressableStyle())
        .onAppear {
            etaState = ProgressStore.cachedETAState
            etaDate  = ProgressStore.cachedETADate
            etaWeeks = ProgressStore.cachedETAWeeks
        }
    }

    // MARK: - Weekly workout average

    private var weeklyWorkoutCard: some View {
        HStack(spacing: 16) {
            workoutAvg(
                title: "Move",
                value: model.weeklyMove > 0 ? "\(Int(model.weeklyMove.rounded()))" : "—",
                unit: "cal/day",
                colors: ActivityRingsView.moveColors
            )
            Rectangle().fill(.white.opacity(0.08)).frame(width: 1, height: 40)
            workoutAvg(
                title: "Exercise",
                value: model.weeklyExercise > 0 ? "\(Int(model.weeklyExercise.rounded()))" : "—",
                unit: "min/day",
                colors: ActivityRingsView.exerciseColors
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .overlay(alignment: .topLeading) {
            Text("THIS WEEK · AVG")
                .font(.caption2.weight(.bold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.top, 12)
                .padding(.leading, 20)
        }
    }

    private func workoutAvg(title: String, value: String, unit: String, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                Text(unit)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 14)
    }

    // MARK: - Countdown hero

    private var heroColor: Color {
        switch model.count {
        case 0:        return .mint
        case 1...6:    return .green
        case 7...14:   return .orange
        case 15...29:  return .yellow
        default:       return Color(red: 0.55, green: 0.82, blue: 1.0)
        }
    }

    private var countdownHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [heroColor.opacity(0.18), Color(white: 0.07)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            RadialGradient(
                colors: [heroColor.opacity(0.28), .clear],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 0, endRadius: 160
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))

            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 10) {
                    MascotView(ringsClosed: model.todayOnTrack, size: 90)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(model.count)")
                            .font(.system(size: 88, weight: .heavy, design: .rounded))
                            .foregroundStyle(heroColor)
                            .shadow(color: heroColor.opacity(0.55), radius: 24)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: model.count)
                            .scaleEffect(model.count == 0 && pulse ? 1.05 : 1.0)
                            .onAppear {
                                guard model.count == 0 else { return }
                                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                    pulse = true
                                }
                            }
                        Text("DAYS TO GO")
                            .font(.caption.weight(.bold))
                            .tracking(4)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4)

                Text(model.todayOnTrack ? "You're being consistent. Keep it up." : "Stay consistent — earn every single day.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 16)

                // Streak chip with freeze snowflakes
                if model.currentStreak > 0 {
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text("\(model.currentStreak)-day streak")
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .foregroundStyle(.white)

                        if model.streakFreezes > 0 {
                            HStack(spacing: 3) {
                                ForEach(0..<model.streakFreezes, id: \.self) { _ in
                                    Image(systemName: "snowflake")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.cyan)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.orange.opacity(0.18))
                            .overlay(Capsule().strokeBorder(.orange.opacity(0.35), lineWidth: 1))
                    )
                    .padding(.top, 14)
                } else if model.streakFreezes > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<model.streakFreezes, id: \.self) { _ in
                            Image(systemName: "snowflake")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.cyan)
                        }
                        Text("freeze\(model.streakFreezes == 1 ? "" : "s") saved")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.cyan.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.cyan.opacity(0.1))
                        .overlay(Capsule().strokeBorder(.cyan.opacity(0.3), lineWidth: 1)))
                    .padding(.top, 14)
                }

                // Progress bar
                VStack(spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [heroColor.opacity(0.7), heroColor],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geo.size.width * model.progress))
                                .animation(.easeInOut(duration: 0.6), value: model.progress)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(Int(model.progress * 100))% complete")
                            .foregroundStyle(heroColor.opacity(0.85))
                        Spacer()
                        if model.todayOnTrack {
                            Label("Today counts!", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Close rings to earn today", systemImage: "circle.dashed")
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .font(.caption2)
                }
                .padding(.top, 16)
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Activity card

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Activity")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 20) {
                ActivityRingsView(ring: model.ring, lineWidth: 18, spacing: 6, animated: true)
                    .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 18) {
                    metric(title: "Move",
                           value: Int(model.ring.moveCurrent),
                           goal: model.ring.moveGoal,
                           unit: "CAL",
                           colors: ActivityRingsView.moveColors)
                    metric(title: "Exercise",
                           value: Int(model.ring.exerciseCurrent),
                           goal: model.ring.exerciseGoal,
                           unit: "MIN",
                           colors: ActivityRingsView.exerciseColors)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func metric(title: String, value: Int, goal: Double, unit: String, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(goal > 0 ? "/\(Int(goal))" : "/--")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text(unit)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
        }
    }

    // MARK: - Daily quote

    private var quoteCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .foregroundStyle(.mint.opacity(0.7))
            Text(model.todayQuote)
                .font(.callout.italic())
                .foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - 7-day history strip

    private var historyStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                ForEach(Array(model.history.enumerated()), id: \.offset) { idx, entry in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(color(for: entry.status))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: icon(for: entry.status))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black.opacity(0.55))
                            )
                        Text(weekdayInitial(entry.date))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(historyAppeared ? 1 : 0)
                    .scaleEffect(historyAppeared ? 1 : 0.6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(idx) * 0.06), value: historyAppeared)
                }
            }
            .onAppear { historyAppeared = true }

            // Legend when a freeze was used this week
            if model.history.contains(where: { $0.status == .frozen }) {
                HStack(spacing: 5) {
                    Image(systemName: "snowflake").font(.caption2).foregroundStyle(.cyan)
                    Text("Streak freeze used").font(.caption2).foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func color(for status: DayStatus) -> Color {
        switch status {
        case .good:   return .green
        case .bad:    return .red
        case .frozen: return .cyan
        case .none:   return .white.opacity(0.18)
        }
    }

    private func icon(for status: DayStatus) -> String {
        switch status {
        case .good:   return "checkmark"
        case .bad:    return "xmark"
        case .frozen: return "snowflake"
        case .none:   return ""
        }
    }

    private func weekdayInitial(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f.string(from: date)
    }

    // MARK: - Stats card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stats")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button { showAchievements = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "rosette")
                        Text("\(model.unlockedAchievements.count)")
                        Text("/ \(AchievementKind.allCases.count)")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                }
                .buttonStyle(PressableStyle())
            }

            HStack(spacing: 12) {
                stat("Current", "\(model.currentStreak)", "streak", .orange)
                stat("Best", "\(model.bestStreak)", "streak", .yellow)
            }
            HStack(spacing: 12) {
                stat("Good", "\(model.totalGoodDays)", "days", .green)
                stat("Missed", "\(model.totalBadDays)", "days", .red)
            }
            HStack {
                Text("Net days saved")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(model.netDaysSaved >= 0 ? "+" : "")\(model.netDaysSaved)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(model.netDaysSaved >= 0 ? .mint : .red)
            }
            .padding(.top, 2)

            Divider().overlay(.white.opacity(0.08))

            Button { showGameCenter = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.mint)
                    Text("Game Center Leaderboard")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            .buttonStyle(PressableStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func stat(_ title: String, _ value: String, _ unit: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
    }

    // MARK: - Manual adjustment buttons

    private var penaltyButton: some View {
        VStack(spacing: 10) {
            actionButton(
                title: "Remove 1 Day",
                subtitle: "Reward yourself for a great day",
                icon: "minus",
                tint: Color(red: 0.20, green: 0.85, blue: 0.65),
                action: { model.addManualCredit() }
            )
            actionButton(
                title: "Add Penalty Day",
                subtitle: "Bad eating or skipped the gym",
                icon: "plus",
                tint: Color(red: 1.0, green: 0.45, blue: 0.25),
                action: { model.addManualPenalty() }
            )
        }
        .padding(.top, 4)
    }

    private func actionButton(title: String, subtitle: String, icon: String,
                               tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(tint.opacity(0.15)).frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableStyle())
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(white: 0.10))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.07), lineWidth: 1))
    }
}

// MARK: -

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
