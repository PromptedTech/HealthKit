import SwiftUI
import Charts
import PhotosUI
import LocalAuthentication

struct ProgressScreen: View {

    @StateObject private var model = ProgressViewModel()
    @State private var showLogSheet = false
    @State private var showPhotoSheet = false
    @State private var selectedPose: Pose = .front
    @State private var showTargetSheet = false
    @State private var isLocked = false
    @State private var authChecked = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLocked {
                    lockedView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showLogSheet = true } label: {
                        Image(systemName: "plus.circle")
                    }
                    .tint(.white)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showTargetSheet = true } label: {
                        Image(systemName: "target")
                    }
                    .tint(.white)
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogEntrySheet(model: model)
            }
            .sheet(isPresented: $showPhotoSheet) {
                PhotoCaptureSheet(model: model, selectedPose: $selectedPose)
            }
            .sheet(isPresented: $showTargetSheet) {
                TargetSheet(model: model)
            }
            .task {
                await authenticate()
                await model.refresh()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Lock screen

    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "faceid")
                .font(.system(size: 60))
                .foregroundStyle(.mint)
            Text("Progress is locked")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Authenticate to view your progress photos and body stats.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Unlock") {
                Task { await authenticate() }
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Capsule().fill(.mint))
        }
    }

    // MARK: - Main content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                etaHeroCard
                weightTrendCard
                bodyFatTrendCard
                photosCard
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .refreshable { await model.refresh() }
    }

    // MARK: - Abs ETA hero

    private var etaHeroCard: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(
                        colors: [etaColor.opacity(0.18), Color(white: 0.07)],
                        startPoint: .top, endPoint: .bottom
                    ))

                RadialGradient(
                    colors: [etaColor.opacity(0.25), .clear],
                    center: .init(x: 0.5, y: 0.3),
                    startRadius: 0, endRadius: 140
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))

                VStack(spacing: 16) {
                    // Headline
                    VStack(spacing: 4) {
                        Text(etaHeadline)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(etaColor)
                            .multilineTextAlignment(.center)
                        Text(etaSubline)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }

                    // Stats row
                    HStack(spacing: 0) {
                        etaStat("Now", model.displayCurrentBF, "BF%", .white.opacity(0.7))
                        Divider().frame(height: 36).background(.white.opacity(0.15))
                        etaStat("Target", String(format: "%.0f%%", model.targetBodyFat), "BF%", etaColor)
                        Divider().frame(height: 36).background(.white.opacity(0.15))
                        etaStat("Rate", model.displayWeeklyRate, "", .cyan)
                    }
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))

                    if model.bodyFatIsEstimated {
                        Label("BF% estimated from weight & height", systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(24)
            }
        }
    }

    private var etaColor: Color {
        switch model.etaState {
        case .alreadyThere:  return .mint
        case .onTrack:       return .green
        case .notLosingYet:  return .orange
        case .needMoreData:  return Color(white: 0.6)
        }
    }

    private var etaHeadline: String {
        switch model.etaState {
        case .needMoreData:    return "Log weight a few times"
        case .notLosingYet:   return "Not in a deficit yet"
        case .alreadyThere:   return "You're there! 🎉"
        case .onTrack(let date, let weeks):
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return "Abs by \(fmt.string(from: date)) · \(Int(weeks.rounded()))w"
        }
    }

    private var etaSubline: String {
        switch model.etaState {
        case .needMoreData:   return "Need 4+ weight entries to project your ETA"
        case .notLosingYet:  return "Tighten your calorie deficit to start trending down"
        case .alreadyThere:  return "Your body fat is already at or below your target"
        case .onTrack:       return "Projected from your real fat-loss rate"
        }
    }

    private func etaStat(_ title: String, _ value: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            if !unit.isEmpty {
                Text(unit).font(.caption2).foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Weight trend chart

    private var weightTrendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader("Weight", icon: "scalemass.fill", color: .cyan)

            if model.weightSeries.isEmpty {
                emptyState("No weight data yet.\nLog your weight or add it in the Health app.")
            } else {
                Chart(model.weightSeries, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("kg", point.kg)
                    )
                    .foregroundStyle(.cyan)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("kg", point.kg)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [.cyan.opacity(0.25), .clear],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("kg", point.kg)
                    )
                    .foregroundStyle(.cyan)
                    .symbolSize(20)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisTick().foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .chartYAxis {
                    AxisMarks { v in
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisValueLabel { Text("\(v.as(Double.self).map { Int($0) } ?? 0) kg") }
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - Body fat trend chart

    private var bodyFatTrendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                cardHeader("Body Fat", icon: "chart.line.downtrend.xyaxis", color: .orange)
                Spacer()
                if model.bodyFatIsEstimated {
                    Text("ESTIMATED")
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.orange.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.orange.opacity(0.12)))
                }
            }

            if model.bodyFatSeries.isEmpty {
                emptyState("No body fat data.\nLog it in-app or add body fat % in the Health app.")
            } else {
                Chart(model.bodyFatSeries, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("%", point.pct)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("%", point.pct)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [.orange.opacity(0.25), .clear],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("%", point.pct)
                    )
                    .foregroundStyle(.orange)
                    .symbolSize(20)
                }
                // Target line
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        if let plotFrame = proxy.plotFrame {
                            let y = proxy.position(forY: model.targetBodyFat)
                            Path { path in
                                path.move(to: CGPoint(x: geo[plotFrame].minX, y: y ?? 0))
                                path.addLine(to: CGPoint(x: geo[plotFrame].maxX, y: y ?? 0))
                            }
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(.mint.opacity(0.6))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisTick().foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .chartYAxis {
                    AxisMarks { v in
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisValueLabel { Text("\(v.as(Double.self).map { Int($0) } ?? 0)%") }
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(height: 160)

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(.mint).frame(width: 16, height: 2)
                    Text("Target \(Int(model.targetBodyFat))%")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - Progress photos

    private var photosCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                cardHeader("Progress Photos", icon: "camera.fill", color: .purple)
                Spacer()
                Button {
                    showPhotoSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.purple)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.purple.opacity(0.15)))
                }
            }

            // Pose tabs
            HStack(spacing: 8) {
                ForEach(Pose.allCases) { pose in
                    let count = model.photos(for: pose).count
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPose = pose }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: pose.icon).font(.caption2)
                            Text(pose.label)
                                .font(.caption.weight(.semibold))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selectedPose == pose ? .purple.opacity(0.25) : .white.opacity(0.06))
                                .overlay(Capsule().strokeBorder(selectedPose == pose ? .purple.opacity(0.5) : .clear, lineWidth: 1))
                        )
                        .foregroundStyle(selectedPose == pose ? .purple : .white.opacity(0.6))
                    }
                    .buttonStyle(PressableStyle())
                }
            }

            let posePhotos = model.photos(for: selectedPose)

            if posePhotos.isEmpty {
                Button {
                    showPhotoSheet = true
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.purple.opacity(0.6))
                        Text("Add your first \(selectedPose.label.lowercased()) photo")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
                .buttonStyle(PressableStyle())
            } else {
                // Before / after compare slider if 2+ photos
                if posePhotos.count >= 2,
                   let pair = model.comparePair(for: selectedPose) {
                    CompareSliderView(
                        beforePhoto: pair.first,
                        afterPhoto: pair.latest
                    )
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Photo grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(posePhotos.reversed()) { photo in
                        PhotoThumbView(photo: photo) {
                            model.deletePhoto(photo)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - FaceID

    private func authenticate() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isLocked = false
            authChecked = true
            return
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock your progress photos and body stats"
            )
            isLocked = !success
        } catch {
            isLocked = false   // fall through if FaceID not set up
        }
        authChecked = true
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(white: 0.10))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.07), lineWidth: 1))
    }

    private func cardHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.4))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
    }
}

// MARK: - Compare Slider

struct CompareSliderView: View {
    let beforePhoto: ProgressPhoto
    let afterPhoto: ProgressPhoto

    @State private var sliderPosition: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // After (background — full width)
                if let img = ProgressStore.imageFor(afterPhoto) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }

                // Before (clipped to slider position)
                if let img = ProgressStore.imageFor(beforePhoto) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .mask(
                            Rectangle()
                                .frame(width: geo.size.width * sliderPosition)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }

                // Divider line + handle
                let x = geo.size.width * sliderPosition
                Rectangle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 2)
                    .offset(x: x - 1)

                Circle()
                    .fill(.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left").font(.system(size: 10, weight: .bold))
                            Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.black)
                    )
                    .shadow(radius: 4)
                    .offset(x: x - 18)

                // Labels
                HStack {
                    Text("BEFORE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(.black.opacity(0.5)))
                        .padding(8)
                        .opacity(sliderPosition > 0.15 ? 1 : 0)
                    Spacer()
                    Text("AFTER")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(.black.opacity(0.5)))
                        .padding(8)
                        .opacity(sliderPosition < 0.85 ? 1 : 0)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        sliderPosition = max(0, min(1, value.location.x / geo.size.width))
                    }
            )
        }
    }
}

// MARK: - Photo thumbnail

struct PhotoThumbView: View {
    let photo: ProgressPhoto
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let img = ProgressStore.imageFor(photo) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.05))
                    .frame(height: 100)
                    .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.3)))
            }

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .padding(4)
        }
        .confirmationDialog("Delete this photo?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Log entry sheet

struct LogEntrySheet: View {
    @ObservedObject var model: ProgressViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var weightText = ""
    @State private var bfText = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Form {
                    Section("Weight") {
                        HStack {
                            TextField("e.g. 74.5", text: $weightText)
                                .keyboardType(.decimalPad)
                            Text("kg").foregroundStyle(.secondary)
                        }
                    }
                    Section("Body Fat %") {
                        HStack {
                            TextField("e.g. 18.0", text: $bfText)
                                .keyboardType(.decimalPad)
                            Text("%").foregroundStyle(.secondary)
                        }
                    }
                    Section {
                        Text("These are saved to the Health app and used to project your Abs ETA.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || (weightText.isEmpty && bfText.isEmpty))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() async {
        isSaving = true
        if let kg = Double(weightText.replacingOccurrences(of: ",", with: ".")) {
            await model.logWeight(kg)
        }
        if let pct = Double(bfText.replacingOccurrences(of: ",", with: ".")) {
            await model.logBodyFat(pct)
        }
        isSaving = false
        dismiss()
    }
}

// MARK: - Target body-fat sheet

struct TargetSheet: View {
    @ObservedObject var model: ProgressViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var targetText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Form {
                    Section("Target Body Fat %") {
                        HStack {
                            TextField(String(format: "%.0f", model.targetBodyFat), text: $targetText)
                                .keyboardType(.decimalPad)
                            Text("%").foregroundStyle(.secondary)
                        }
                    }
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Typical abs-visible thresholds:")
                                .font(.footnote.weight(.semibold))
                            Text("Male — around 10–13%")
                            Text("Female — around 16–20%")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Abs Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(targetText.replacingOccurrences(of: ",", with: ".")) {
                            model.setTarget(v)
                        }
                        dismiss()
                    }
                    .disabled(targetText.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Photo capture sheet

struct PhotoCaptureSheet: View {
    @ObservedObject var model: ProgressViewModel
    @Binding var selectedPose: Pose
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedPoseLocal: Pose = .front
    @State private var pendingImage: UIImage?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Pose picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("POSE").font(.caption2.weight(.bold)).tracking(2).foregroundStyle(.white.opacity(0.4))
                        HStack(spacing: 8) {
                            ForEach(Pose.allCases) { pose in
                                Button {
                                    selectedPoseLocal = pose
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: pose.icon)
                                        Text(pose.label).font(.caption)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPoseLocal == pose ? .purple.opacity(0.25) : .white.opacity(0.06))
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(selectedPoseLocal == pose ? .purple.opacity(0.5) : .clear, lineWidth: 1))
                                    )
                                    .foregroundStyle(selectedPoseLocal == pose ? .purple : .white.opacity(0.6))
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Preview
                    if let img = pendingImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.05))
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo.badge.plus").font(.system(size: 40)).foregroundStyle(.white.opacity(0.2)))
                            .padding(.horizontal)
                    }

                    // Source buttons
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.08)))
                                .foregroundStyle(.white)
                        }
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.08)))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let img = pendingImage {
                            model.addPhoto(img, pose: selectedPoseLocal)
                            selectedPose = selectedPoseLocal
                            dismiss()
                        }
                    }
                    .disabled(pendingImage == nil)
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        pendingImage = img
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { img in pendingImage = img }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Camera wrapper

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onCapture(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ProgressScreen()
}
