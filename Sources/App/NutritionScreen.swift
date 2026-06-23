import SwiftUI

struct NutritionScreen: View {

    @StateObject private var model = NutritionViewModel()
    @State private var showAddFood = false
    @State private var showGoalSetup = false
    @State private var barsAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        fuelHero
                        averageCard
                        logCard
                        addButton
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGoalSetup = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .tint(.white)
                }
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodSheet(model: model)
            }
            .sheet(isPresented: $showGoalSetup) {
                GoalSetupSheet()
                    .onDisappear { model.refresh() }
            }
            .onAppear {
                model.refresh()
                // Auto-show setup if no calorie target is set yet
                if model.calorieTarget == 0 {
                    showGoalSetup = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Fuel today hero

    private var calorieTint: Color {
        if model.calorieTarget <= 0 { return .white.opacity(0.4) }
        return model.overCalories ? .red : (model.calorieFraction > 0.85 ? .orange : .mint)
    }

    private var fuelHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [calorieTint.opacity(0.16), Color(white: 0.07)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 18) {
                Text("FUEL TODAY")
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.4))

                if model.needsBodyStats {
                    statsPrompt
                } else {
                    // Calories
                    fuelBar(
                        title: "Calories",
                        value: model.todayKcal,
                        target: model.calorieTarget,
                        unit: "kcal",
                        tint: calorieTint,
                        fraction: model.calorieFraction
                    )
                    // Protein
                    fuelBar(
                        title: "Protein",
                        value: model.todayProtein,
                        target: model.proteinTarget,
                        unit: "g",
                        tint: model.proteinGoalHit ? .green : Color(red: 0.4, green: 0.8, blue: 1.0),
                        fraction: model.proteinFraction
                    )

                    Text(statusLine)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No goals set yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Tap below to set a calorie target — auto-computed from your body stats or a manual number you choose.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showGoalSetup = true
            } label: {
                Label("Set up goals", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.mint))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.vertical, 6)
    }

    private var statusLine: String {
        guard model.calorieTarget > 0 else { return "Log your meals to track today." }
        let remaining = Int(model.caloriesRemaining.rounded())
        if model.proteinGoalHit && !model.overCalories {
            return "Protein goal hit 💪 and \(remaining) kcal under — perfect cutting day."
        }
        if model.overCalories {
            return "\(abs(remaining)) kcal over target — ease up to keep leaning out."
        }
        return "\(remaining) kcal under — on track to lean out."
    }

    private func fuelBar(title: String, value: Double, target: Double,
                         unit: String, tint: Color, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(value.rounded()))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                Text(target > 0 ? "/ \(Int(target.rounded())) \(unit)" : unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [tint.opacity(0.7), tint],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geo.size.width * min(1, fraction)))
                        .animation(.easeInOut(duration: 0.5), value: fraction)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - 7-day average card

    private var averageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("7-Day Average")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if model.loggedDays > 0 {
                    Text("\(model.loggedDays) day\(model.loggedDays == 1 ? "" : "s") logged")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            HStack(spacing: 12) {
                avgStat("Calories", model.avgKcal > 0 ? "\(Int(model.avgKcal.rounded()))" : "—", "kcal/day", .mint)
                avgStat("Protein", model.avgProtein > 0 ? "\(Int(model.avgProtein.rounded()))" : "—", "g/day", Color(red: 0.4, green: 0.8, blue: 1.0))
            }

            trendBars
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var trendBars: some View {
        let maxKcal = max(model.kcalSeries.map(\.kcal).max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(model.kcalSeries.enumerated()), id: \.offset) { idx, entry in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.06))
                            .frame(width: 14, height: 44)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(entry.kcal > 0 ? Color.mint.opacity(0.8) : .clear)
                            .frame(width: 14, height: barsAppeared ? max(3, 44 * (entry.kcal / maxKcal)) : 3)
                            .animation(.spring(response: 0.45, dampingFraction: 0.75).delay(Double(idx) * 0.05), value: barsAppeared)
                    }
                    Text(weekdayInitial(entry.date))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { barsAppeared = true }
    }

    private func avgStat(_ title: String, _ value: String, _ unit: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                Text(unit)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
    }

    // MARK: - Today's log

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Log")
                .font(.headline)
                .foregroundStyle(.white)

            if model.todayEntries.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "fork.knife.circle")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("Nothing logged yet. Tap “Add food” to start.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.vertical, 6)
            } else {
                ForEach(model.todayEntries) { entry in
                    foodRow(entry)
                    if entry.id != model.todayEntries.last?.id {
                        Divider().overlay(.white.opacity(0.08))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func foodRow(_ entry: FoodEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(servingLabel(entry))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.totalKcal.rounded())) kcal")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.mint)
                Text("\(Int(entry.totalProtein.rounded())) g protein")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Button {
                withAnimation { model.remove(entry) }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func servingLabel(_ entry: FoodEntry) -> String {
        let s = entry.servings
        let count = s == s.rounded() ? "\(Int(s))" : String(format: "%.1f", s)
        return "\(count)× serving"
    }

    // MARK: - Add button

    private var addButton: some View {
        Button { showAddFood = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.mint.opacity(0.15)).frame(width: 42, height: 42)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.mint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add food")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Search the library and log a portion")
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
                            .strokeBorder(.mint.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - Shared helpers

    private func weekdayInitial(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f.string(from: date)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(white: 0.10))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.07), lineWidth: 1))
    }
}

// MARK: - Add food sheet

private struct AddFoodSheet: View {

    @ObservedObject var model: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var selectedCategory: FoodCategory? = nil
    @State private var pendingItem: FoodItem? = nil
    @State private var portion: Double = 1.0

    private var results: [FoodItem] {
        var items = FoodLibrary.search(query)
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchField

                    if query.isEmpty && selectedCategory == nil {
                        recentsRow
                    }

                    categoryChips

                    List {
                        ForEach(results) { item in
                            Button { open(item) } label: { itemRow(item) }
                                .listRowBackground(Color(white: 0.10))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $pendingItem) { item in
                portionSheet(item)
                    .presentationDetents([.height(280)])
            }
        }
        .preferredColorScheme(.dark)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.4))
            TextField("Search foods…", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.07)))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var recentsRow: some View {
        let recents = model.recentFoods()
        return Group {
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RECENT")
                        .font(.caption2.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recents) { entry in
                                Button { relog(entry) } label: {
                                    Text(entry.name)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(.white.opacity(0.08)))
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", active: selectedCategory == nil) { selectedCategory = nil }
                ForEach(FoodCategory.allCases) { cat in
                    chip(title: cat.label, active: selectedCategory == cat) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private func chip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(active ? .black : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(active ? Color.mint : .white.opacity(0.08)))
        }
        .buttonStyle(PressableStyle())
    }

    private func itemRow(_ item: FoodItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.system(size: 14))
                .foregroundStyle(.mint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(item.serving)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.kcal)) kcal")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(Int(item.protein)) g P")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }

    private func portionSheet(_ item: FoodItem) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(item.serving)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 20)

            HStack(spacing: 24) {
                stepButton("minus") { portion = max(0.5, portion - 0.5) }
                VStack(spacing: 0) {
                    Text(portion == portion.rounded() ? "\(Int(portion))" : String(format: "%.1f", portion))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.mint)
                    Text("servings")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(minWidth: 90)
                stepButton("plus") { portion = min(20, portion + 0.5) }
            }

            Text("\(Int((item.kcal * portion).rounded())) kcal · \(Int((item.protein * portion).rounded())) g protein")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            Button {
                model.log(item: item, servings: portion)
                pendingItem = nil
                dismiss()
            } label: {
                Text("Add to today")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.mint))
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(white: 0.08).ignoresSafeArea())
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill(.white.opacity(0.1)))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
    }

    private func open(_ item: FoodItem) {
        portion = 1.0
        pendingItem = item
    }

    private func relog(_ entry: FoodEntry) {
        model.relog(entry, servings: entry.servings)
        dismiss()
    }
}

// MARK: - Goal setup sheet

struct GoalSetupSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var mode: NutritionGoalMode = NutritionStore.goalMode
    @State private var weightKg: Double = NutritionStore.weightKg == 0 ? 70 : NutritionStore.weightKg
    @State private var heightCm: Double = NutritionStore.heightCm == 0 ? 170 : NutritionStore.heightCm
    @State private var age: Int = NutritionStore.age == 0 ? 25 : NutritionStore.age
    @State private var sex: Sex = NutritionStore.sex
    @State private var activity: ActivityLevel = NutritionStore.activityLevel
    @State private var deficit: Double = NutritionStore.deficitPercent
    @State private var manualCals: Double = NutritionStore.manualCalorieGoal
    @State private var manualProtein: Double = NutritionStore.manualProteinGoal

    private var previewTarget: String {
        if mode == .auto {
            guard weightKg > 0 && heightCm > 0 && age > 0 else { return "Enter stats to see target" }
            let bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + (sex == .male ? 5 : -161)
            let tdee = bmr * activity.factor
            let floor = sex == .male ? 1500.0 : 1200.0
            let cals = max(floor, tdee * (1 - deficit / 100)).rounded()
            let protein = (weightKg * 1.8).rounded()
            return "\(Int(cals)) kcal  ·  \(Int(protein)) g protein / day"
        } else {
            return "\(Int(manualCals)) kcal  ·  \(Int(manualProtein)) g protein / day"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Mode picker
                        VStack(alignment: .leading, spacing: 10) {
                            label("Goal type")
                            Picker("Mode", selection: $mode) {
                                Text("Auto — cut for abs").tag(NutritionGoalMode.auto)
                                Text("Manual").tag(NutritionGoalMode.manual)
                            }
                            .pickerStyle(.segmented)
                        }

                        if mode == .auto {
                            autoFields
                        } else {
                            manualFields
                        }

                        // Live preview
                        VStack(spacing: 6) {
                            Text("DAILY TARGET")
                                .font(.caption2.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.4))
                            Text(previewTarget)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.mint)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.05)))

                        Button {
                            save()
                            dismiss()
                        } label: {
                            Text("Save goals")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(Color.mint))
                        }
                        .buttonStyle(PressableStyle())
                        .disabled(mode == .auto && (weightKg == 0 || heightCm == 0 || age == 0))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Set up goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var autoFields: some View {
        VStack(spacing: 16) {
            numberField(label: "Weight (kg)", value: $weightKg, range: 35...200, step: 0.5)
            numberField(label: "Height (cm)", value: $heightCm, range: 120...220, step: 1)
            intField(label: "Age", value: $age, range: 12...90)

            pickField("Sex") {
                Picker("Sex", selection: $sex) {
                    ForEach(Sex.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            pickField("Activity level") {
                Picker("Activity", selection: $activity) {
                    ForEach(ActivityLevel.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            numberField(label: "Deficit %", value: $deficit, range: 5...35, step: 5,
                        footer: "% below maintenance. 20% is a safe, steady cut.")
        }
    }

    private var manualFields: some View {
        VStack(spacing: 16) {
            numberField(label: "Daily calories (kcal)", value: $manualCals, range: 800...5000, step: 50,
                        footer: "Your total daily calorie target.")
            numberField(label: "Daily protein (g)", value: $manualProtein, range: 20...300, step: 5,
                        footer: "Aim for ≥1.6 g/kg bodyweight to keep muscle while cutting.")
        }
    }

    private func numberField(label lbl: String, value: Binding<Double>,
                             range: ClosedRange<Double>, step: Double,
                             footer: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            self.label(lbl)
            HStack {
                Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - step) } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.08)))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
                Spacer()
                Text(value.wrappedValue == value.wrappedValue.rounded(.towardZero) && step >= 1
                     ? "\(Int(value.wrappedValue))"
                     : String(format: "%.1f", value.wrappedValue))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minWidth: 80, alignment: .center)
                Spacer()
                Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + step) } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.08)))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
            }
            .foregroundStyle(.white)
            if let f = footer {
                Text(f).font(.caption2).foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
    }

    private func intField(label lbl: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            self.label(lbl)
            HStack {
                Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.08)))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
                Spacer()
                Text("\(value.wrappedValue)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minWidth: 80, alignment: .center)
                Spacer()
                Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.08)))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
            }
            .foregroundStyle(.white)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
    }

    private func pickField<Content: View>(_ lbl: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label(lbl)
            content()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.8))
    }

    private func save() {
        NutritionStore.goalMode = mode
        if mode == .auto {
            NutritionStore.weightKg = weightKg
            NutritionStore.heightCm = heightCm
            NutritionStore.age = age
            NutritionStore.sex = sex
            NutritionStore.activityLevel = activity
            NutritionStore.deficitPercent = deficit
        } else {
            NutritionStore.manualCalorieGoal = manualCals
            NutritionStore.manualProteinGoal = manualProtein
        }
    }
}
