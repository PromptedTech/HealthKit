import SwiftUI

struct SettingsView: View {

    @ObservedObject var model: CountdownViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var resetValue: Int = CountdownStore.currentCount
    @State private var customEnabled: Bool = CountdownStore.customGoalsEnabled
    @State private var customMove: Double = CountdownStore.customMoveGoal
    @State private var customExercise: Double = CountdownStore.customExerciseGoal
    @State private var showGoalSetup = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Counter") {
                    Stepper(value: $resetValue, in: 0...365) {
                        HStack {
                            Text("Set days to")
                            Spacer()
                            Text("\(resetValue)").foregroundStyle(.secondary)
                        }
                    }
                    Button("Reset counter to \(resetValue)") {
                        model.reset(to: resetValue)
                    }
                }

                Section {
                    Toggle("Use custom goals", isOn: $customEnabled)
                    if customEnabled {
                        Stepper(value: $customMove, in: 100...2000, step: 50) {
                            HStack {
                                Text("Move goal")
                                Spacer()
                                Text("\(Int(customMove)) CAL").foregroundStyle(.secondary)
                            }
                        }
                        Stepper(value: $customExercise, in: 5...180, step: 5) {
                            HStack {
                                Text("Exercise goal")
                                Spacer()
                                Text("\(Int(customExercise)) MIN").foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Challenge goals")
                } footer: {
                    Text("Override your Apple Watch goals to make a day harder to earn. When on, both rings must hit these targets to count.")
                }

                Section {
                    Button {
                        showGoalSetup = true
                    } label: {
                        HStack {
                            Label("Edit nutrition goals", systemImage: "slider.horizontal.3")
                            Spacer()
                            Text(currentGoalSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Nutrition goals")
                } footer: {
                    Text("Set your daily calorie & protein target — auto-computed from body stats or a manual number.")
                }
                .sheet(isPresented: $showGoalSetup) {
                    GoalSetupSheet()
                }

                Section("Today's rings") {
                    Button {
                        Task { await model.evaluateNow() }
                    } label: {
                        if model.isEvaluating {
                            ProgressView()
                        } else {
                            Label("Re-check rings now", systemImage: "arrow.clockwise")
                        }
                    }
                    ringRow("Move", value: Int(model.ring.moveCurrent),
                            goal: model.ring.moveGoal, unit: "CAL", closed: model.ring.moveClosed)
                    ringRow("Exercise", value: Int(model.ring.exerciseCurrent),
                            goal: model.ring.exerciseGoal, unit: "MIN", closed: model.ring.exerciseClosed)
                }

                Section("Manual penalties (\(model.penalties.count))") {
                    if model.penalties.isEmpty {
                        Text("No penalties yet. Keep it up!")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.penalties.reversed(), id: \.self) { date in
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { resetValue = model.count }
            .onChange(of: customEnabled) { _, newValue in
                CountdownStore.customGoalsEnabled = newValue
                Task { await model.evaluateNow() }
            }
            .onChange(of: customMove) { _, newValue in
                CountdownStore.customMoveGoal = newValue
                if customEnabled { Task { await model.evaluateNow() } }
            }
            .onChange(of: customExercise) { _, newValue in
                CountdownStore.customExerciseGoal = newValue
                if customEnabled { Task { await model.evaluateNow() } }
            }
        }
    }

    private var currentGoalSummary: String {
        let cal = NutritionStore.calorieTarget
        let pro = NutritionStore.proteinTarget
        guard cal > 0 else { return "Not set" }
        return "\(Int(cal)) kcal · \(Int(pro)) g"
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func ringRow(_ title: String, value: Int, goal: Double, unit: String, closed: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(goal > 0 ? "\(value)/\(Int(goal)) \(unit)" : "No data")
                .foregroundStyle(.secondary)
            Image(systemName: closed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(closed ? .green : .secondary)
        }
    }
}
