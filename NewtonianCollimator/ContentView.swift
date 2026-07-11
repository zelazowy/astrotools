import SwiftUI

struct ContentView: View {
    private enum AstroTool: String, CaseIterable, Identifiable {
        case collimation
        case flatPanel

        var id: String { rawValue }

        var title: String {
            switch self {
            case .collimation:
                "Collimation"
            case .flatPanel:
                "Flat Panel"
            }
        }

        var icon: String {
            switch self {
            case .collimation:
                "scope"
            case .flatPanel:
                "sun.max"
            }
        }
    }

    private enum FlatTint: String, CaseIterable, Identifiable {
        case pureWhite
        case lightGray
        case middleGray
        case warmWhite

        var id: String { rawValue }

        var title: String {
            switch self {
            case .pureWhite:
                "White"
            case .lightGray:
                "Light Gray"
            case .middleGray:
                "Mid Gray"
            case .warmWhite:
                "Warm"
            }
        }
    }

    @StateObject private var cameraManager = CameraManager()
    @StateObject private var screenBrightnessController = ScreenBrightnessController()
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTool: AstroTool = .collimation
    @State private var centerOffset: CGSize = .zero
    @State private var circleRadii: [CGFloat] = [72, 132, 192]
    @State private var isControlPanelVisible = false
    @State private var isAboutVisible = false
    @State private var controlsOffset: CGSize = .zero
    @State private var controlsDragStartOffset: CGSize?
    @State private var flatBrightness = 0.7
    @State private var flatTint: FlatTint = .pureWhite

    var body: some View {
        ZStack {
            if selectedTool == .collimation {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()

                Color.black
                    .opacity(cameraManager.authorizationStatus == .authorized ? 0 : 0.92)
                    .ignoresSafeArea()

                CollimationOverlay(
                    circleRadii: circleRadii,
                    lineWidth: 3,
                    overlayOpacity: 0.95,
                    centerOffset: $centerOffset
                )
            } else {
                flatPanelView
            }
        }
        .background(Color.black)
        .overlay(alignment: .bottom) {
            bottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
        .overlay {
            if isControlPanelVisible {
                controlsOverlay
            }
        }
        .overlay(alignment: .top) {
            if selectedTool == .collimation, cameraManager.authorizationStatus != .authorized {
                permissionCard
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
            }
        }
        .task {
            updateActiveTool()
        }
        .onChange(of: selectedTool) { _, _ in
            isControlPanelVisible = false
            controlsOffset = .zero
            controlsDragStartOffset = nil
            updateActiveTool()
        }
        .onChange(of: flatBrightness) { _, _ in
            syncFlatPanelBrightness()
        }
        .onChange(of: scenePhase) { _, _ in
            syncFlatPanelBrightness()
        }
        .onDisappear {
            cameraManager.stop()
            screenBrightnessController.deactivate()
        }
        .alert(
            "Camera Notice",
            isPresented: Binding(
                get: { cameraManager.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        cameraManager.clearError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                cameraManager.clearError()
            }
        } message: {
            Text(cameraManager.errorMessage ?? "")
        }
        .alert("About", isPresented: $isAboutVisible) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Newtonian Collimator\n\nCurrent tools:\n• Collimation helper\n• Flat panel for capturing flats")
        }
        .animation(.easeInOut(duration: 0.2), value: isControlPanelVisible)
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Camera access required")
                .font(.headline)
            Text("Grant camera permission to view the live telescope image behind the collimation overlay.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedTool == .collimation ? "Overlay Controls" : "Flat Panel")
                    .font(.headline)
                Spacer()
                Image(systemName: "hand.draw")
                    .foregroundStyle(.white.opacity(0.65))
            }

            if selectedTool == .collimation {
                ForEach(circleRadii.indices, id: \.self) { index in
                    LabeledSlider(
                        title: "Circle \(index + 1)",
                        value: radiusBinding(for: index),
                        range: 24...320,
                        valueFormatter: { "\(Int($0)) px" }
                    )
                }
            } else {
                LabeledSlider(
                    title: "Brightness",
                    value: $flatBrightness,
                    range: 0.05...1.0,
                    valueFormatter: { String(format: "%.0f%%", $0 * 100) }
                )

                Picker("Color", selection: $flatTint) {
                    ForEach(FlatTint.allCases) { tint in
                        Text(tint.title).tag(tint)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(width: 310)
    }

    private var controlsOverlay: some View {
        GeometryReader { geometry in
            controlPanel
                .offset(
                    x: controlsOffset.width,
                    y: max(-(geometry.size.height * 0.55), controlsOffset.height)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 92)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if controlsDragStartOffset == nil {
                                controlsDragStartOffset = controlsOffset
                            }

                            let startOffset = controlsDragStartOffset ?? .zero
                            controlsOffset = CGSize(
                                width: startOffset.width + value.translation.width,
                                height: startOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            controlsDragStartOffset = nil
                        }
                )
        }
    }

    private var bottomBar: some View {
        HStack {
            Button("About") {
                isAboutVisible = true
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Spacer()

            Menu {
                ForEach(AstroTool.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        Label(tool.title, systemImage: tool.icon)
                    }
                }
            } label: {
                Label(selectedTool.title, systemImage: selectedTool.icon)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.55), in: Capsule())
            }
            .tint(.white)

            Spacer()

            Button {
                isControlPanelVisible.toggle()
            } label: {
                Label(isControlPanelVisible ? "Hide Controls" : "Show Controls", systemImage: "slider.horizontal.3")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .clipShape(Circle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.42), in: Capsule())
    }

    private func radiusBinding(for index: Int) -> Binding<Double> {
        Binding(
            get: { Double(circleRadii[index]) },
            set: { circleRadii[index] = CGFloat($0) }
        )
    }

    private var flatPanelView: some View {
        flatColor
            .ignoresSafeArea()
    }

    private var flatColor: Color {
        switch flatTint {
        case .pureWhite:
            return Color(red: 1.0, green: 1.0, blue: 1.0)
        case .lightGray:
            return Color(red: 0.82, green: 0.82, blue: 0.82)
        case .middleGray:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .warmWhite:
            return Color(red: 1.0, green: 0.96, blue: 0.88)
        }
    }

    private func updateActiveTool() {
        if selectedTool == .collimation {
            cameraManager.start()
            screenBrightnessController.deactivate()
        } else {
            cameraManager.stop()
            syncFlatPanelBrightness()
        }
    }

    private func syncFlatPanelBrightness() {
        if selectedTool == .flatPanel, scenePhase == .active {
            screenBrightnessController.activate(brightness: flatBrightness)
        } else {
            screenBrightnessController.deactivate()
        }
    }
}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueFormatter: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueFormatter(value))
                    .foregroundStyle(.white.opacity(0.72))
                    .monospacedDigit()
            }
            .font(.subheadline)

            Slider(value: $value, in: range)
                .tint(.green)
        }
    }
}
