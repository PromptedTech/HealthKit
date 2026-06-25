import SwiftUI

// MARK: - Main tab

struct WorkoutScreen: View {
    @StateObject private var logger = WorkoutLogger()
    @State private var records: [WorkoutRecord] = []
    @State private var showKindDialog = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()

                if records.isEmpty {
                    emptyState
                } else {
                    recordsList
                }

                startButton
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.mint)
        .preferredColorScheme(.dark)
        .onAppear { records = WorkoutStore.records }
        .fullScreenCover(isPresented: $logger.isActive) {
            activeWorkoutView
        }
        .confirmationDialog("Start Workout", isPresented: $showKindDialog, titleVisibility: .visible) {
            Button("Strength Training") { logger.startStrength() }
            ForEach(WorkoutKind.CardioType.allCases, id: \.self) { type in
                Button(type.label) { logger.startCardio(type) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var activeWorkoutView: some View {
        if logger.isStrength {
            StrengthWorkoutView(logger: logger, onFinish: saveAndRefresh)
        } else {
            CardioWorkoutView(logger: logger, onFinish: saveAndRefresh)
        }
    }

    private func saveAndRefresh() {
        Task {
            await logger.finishSession()
            records = WorkoutStore.records
        }
    }

    // MARK: - Start button

    private var startButton: some View {
        Button { showKindDialog = true } label: {
            Label("Start Workout", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.mint)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.15))
            Text("No workouts yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Tap Start Workout to log your first session.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 80)
    }

    // MARK: - Records list

    private var recordsList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(records) { record in
                    WorkoutRecordRow(record: record) {
                        WorkoutStore.delete(id: record.id)
                        records = WorkoutStore.records
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 88)
        }
    }
}

// MARK: - Record row

private struct WorkoutRecordRow: View {
    let record: WorkoutRecord
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: record.kind.icon)
                .font(.title2)
                .foregroundStyle(.mint)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.kind.label)
                    .font(.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(record.date, style: .date)
                    if let stats = statsText {
                        Text("·")
                        Text(stats)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Text(record.durationString)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(14)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var statsText: String? {
        if let sets = record.totalSets, let vol = record.totalVolumeKg {
            return "\(sets) sets · \(Int(vol)) kg"
        } else if let dist = record.distanceKm, let kcal = record.calories {
            return String(format: "%.2f km · %.0f kcal", dist, kcal)
        } else if let dist = record.distanceKm {
            return String(format: "%.2f km", dist)
        } else if let kcal = record.calories {
            return String(format: "%.0f kcal", kcal)
        } else if let sets = record.totalSets {
            return "\(sets) sets"
        }
        return nil
    }
}

// MARK: - Strength workout view

struct StrengthWorkoutView: View {
    @ObservedObject var logger: WorkoutLogger
    let onFinish: () -> Void

    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    @State private var addSetForID: UUID? = nil
    @State private var showConfirmFinish = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        sessionTimer

                        if logger.exercises.isEmpty {
                            strengthEmptyHint
                        } else {
                            ForEach(logger.exercises) { exercise in
                                ExerciseCard(
                                    exercise: exercise,
                                    onAddSet: { addSetForID = exercise.id },
                                    onDelete: { logger.removeExercise(withID: exercise.id) }
                                )
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, logger.restTimerActive ? 100 : 20)
                }

                if logger.restTimerActive {
                    RestBanner(logger: logger)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Strength")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { logger.cancelSession() }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 18) {
                        Button {
                            showAddExercise = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        Button("Finish") {
                            showConfirmFinish = true
                        }
                        .fontWeight(.semibold)
                        .disabled(logger.exercises.isEmpty || logger.isSaving)
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseSheet(
                    name: $newExerciseName,
                    onAdd: { name in
                        logger.addExercise(name: name)
                        newExerciseName = ""
                        showAddExercise = false
                    },
                    onCancel: {
                        newExerciseName = ""
                        showAddExercise = false
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { addSetForID != nil },
                set: { if !$0 { addSetForID = nil } }
            )) {
                if let id = addSetForID {
                    AddSetSheet(
                        lastSet: logger.exercises.first(where: { $0.id == id })?.sets.last,
                        onLog: { reps, weight, startRest in
                            logger.appendSet(to: id, reps: reps, weightKg: weight)
                            addSetForID = nil
                            if startRest { logger.startRest(seconds: 90) }
                        },
                        onCancel: { addSetForID = nil }
                    )
                }
            }
            .confirmationDialog("Save this workout?", isPresented: $showConfirmFinish) {
                Button("Save & Finish") { onFinish() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .tint(.mint)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(true)
    }

    private var sessionTimer: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock").foregroundStyle(.mint)
            Text(elapsedText)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(white: 0.1), in: Capsule())
    }

    private var elapsedText: String {
        let m = logger.elapsedSecs / 60
        let s = logger.elapsedSecs % 60
        return String(format: "%d:%02d", m, s)
    }

    private var strengthEmptyHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.15))
            Text("Tap + to add your first exercise")
                .foregroundStyle(.white.opacity(0.4))
                .font(.subheadline)
        }
        .padding(.top, 60)
    }
}

// MARK: - Exercise card

private struct ExerciseCard: View {
    let exercise: Exercise
    let onAddSet: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            if !exercise.sets.isEmpty {
                Divider()
                    .background(.white.opacity(0.1))
                    .padding(.top, 8)

                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { i, set in
                    HStack {
                        Text("Set \(i + 1)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.35))
                            .frame(width: 44, alignment: .leading)
                        Text("\(set.reps) reps")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(String(format: "%.1f kg", set.weightKg))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.mint)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(white: 0.05))
                }

                Divider().background(.white.opacity(0.1))
            }

            HStack {
                Button(action: onAddSet) {
                    Label("Add Set", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.mint)
                }
                Spacer()
                if exercise.totalVolumeKg > 0 {
                    Text(String(format: "%.0f kg vol", exercise.totalVolumeKg))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Rest banner

private struct RestBanner: View {
    @ObservedObject var logger: WorkoutLogger

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Rest", systemImage: "timer")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(logger.restSecondsLeft)s")
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundStyle(.mint)
                    .contentTransition(.numericText())
                Spacer()
                Button("Skip") { logger.stopRestTimer() }
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            GeometryReader { geo in
                let ratio = logger.restTotalSecs > 0
                    ? Double(logger.restSecondsLeft) / Double(logger.restTotalSecs)
                    : 0
                Rectangle()
                    .fill(Color.mint.opacity(0.5))
                    .frame(width: geo.size.width * ratio)
                    .animation(.linear(duration: 1), value: logger.restSecondsLeft)
            }
            .frame(height: 3)
        }
        .background(.black.opacity(0.92))
        .overlay(alignment: .top) {
            Divider().background(.white.opacity(0.1))
        }
    }
}

// MARK: - Add exercise sheet

private struct AddExerciseSheet: View {
    @Binding var name: String
    let onAdd: (String) -> Void
    let onCancel: () -> Void

    private let common = [
        "Bench Press", "Squat", "Deadlift", "Overhead Press",
        "Pull-Up", "Barbell Row", "Dumbbell Curl", "Tricep Dip",
        "Leg Press", "Romanian DL", "Lateral Raise", "Plank"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Exercise name", text: $name)
                        .padding(12)
                        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    Text("Quick picks")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(common, id: \.self) { ex in
                            Button(ex) { onAdd(ex) }
                                .buttonStyle(.bordered)
                                .tint(.mint)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { onAdd(name) }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Add set sheet

private struct AddSetSheet: View {
    let lastSet: ExerciseSet?
    let onLog: (Int, Double, Bool) -> Void
    let onCancel: () -> Void

    @State private var reps: Int
    @State private var weightKg: Double
    @State private var startRest = true

    init(lastSet: ExerciseSet?, onLog: @escaping (Int, Double, Bool) -> Void, onCancel: @escaping () -> Void) {
        self.lastSet = lastSet
        self.onLog = onLog
        self.onCancel = onCancel
        _reps = State(initialValue: lastSet?.reps ?? 8)
        _weightKg = State(initialValue: lastSet?.weightKg ?? 20)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reps") {
                    Stepper("\(reps) reps", value: $reps, in: 1...200)
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Weight")
                            Spacer()
                            Text(String(format: "%.1f kg", weightKg))
                                .font(.system(.body, design: .monospaced).weight(.semibold))
                                .foregroundStyle(.mint)
                        }
                        Slider(value: $weightKg, in: 0...300, step: 2.5)
                            .tint(.mint)
                        HStack(spacing: 8) {
                            ForEach([5.0, 10.0, 20.0, 40.0, 60.0, 80.0, 100.0], id: \.self) { preset in
                                Button(String(format: "%.0f", preset)) {
                                    weightKg = preset
                                }
                                .buttonStyle(.bordered)
                                .tint(.mint)
                                .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Weight (kg)")
                }

                Section {
                    Toggle("Start 90s rest timer after logging", isOn: $startRest)
                }
            }
            .navigationTitle("Log Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log") { onLog(reps, weightKg, startRest) }
                        .fontWeight(.bold)
                        .tint(.mint)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Cardio workout view

struct CardioWorkoutView: View {
    @ObservedObject var logger: WorkoutLogger
    let onFinish: () -> Void

    @State private var distanceText = ""
    @State private var caloriesText = ""
    @State private var showConfirmFinish = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Type header
                    VStack(spacing: 8) {
                        Image(systemName: logger.cardioType.icon)
                            .font(.system(size: 52))
                            .foregroundStyle(.mint)
                        Text(logger.cardioType.label)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 24)

                    // Elapsed timer
                    Text(elapsedText)
                        .font(.system(size: 68, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    // Metric fields
                    HStack(spacing: 14) {
                        CardioMetricField(
                            label: "Distance (km)",
                            icon: "arrow.left.and.right",
                            text: $distanceText
                        )
                        .onChange(of: distanceText) { _, v in logger.distanceKm = Double(v) ?? 0 }

                        CardioMetricField(
                            label: "Calories",
                            icon: "flame.fill",
                            text: $caloriesText
                        )
                        .onChange(of: caloriesText) { _, v in logger.caloriesBurned = Double(v) ?? 0 }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Finish button
                    Button {
                        showConfirmFinish = true
                    } label: {
                        Label("Finish Workout", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mint)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(logger.isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(logger.cardioType.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { logger.cancelSession() }
                        .foregroundStyle(.red)
                }
            }
            .confirmationDialog("Save this workout?", isPresented: $showConfirmFinish) {
                Button("Save & Finish") { onFinish() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .tint(.mint)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(true)
    }

    private var elapsedText: String {
        let h = logger.elapsedSecs / 3600
        let m = (logger.elapsedSecs % 3600) / 60
        let s = logger.elapsedSecs % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}

private struct CardioMetricField: View {
    let label: String
    let icon: String
    @Binding var text: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.mint)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 30, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(16)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}
