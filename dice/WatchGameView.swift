//
//  WatchGameView.swift
//  dice watch Watch App
//
//  Created by G.J. Parker on 11/19/26.
//  Copyright © 2026 G.J. Parker. All rights reserved.
//

import SwiftUI
import SceneKit
import WatchKit
import CoreMotion
import Combine

// MARK: - SceneKit Physics Loop Delegate

final class WatchSceneDelegate: NSObject, SCNSceneRendererDelegate {
    weak var world: World?

    init(world: World) {
        self.world = world
    }

    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        world?.isPaused = false
        world?.update(time)
    }
}

// MARK: - Watch Dice Controller

@MainActor
final class WatchDiceController: ObservableObject {
    let world: World
    let delegate: WatchSceneDelegate

    @Published var selectedType: DieType = .dice6
    @Published var dieCount: Int = 2
    @Published var crownIndex: Double = 0
    @Published var resultText: String = "Tap or shake"
    @Published var isRolling: Bool = false
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    @Published var isSoundOn: Bool = false { didSet { world.sound = isSoundOn } }
    @Published var launchType: LaunchType = .scatter { didSet { world.launchType = launchType } }
    @Published var launchPower: Float = 1.0 { didSet { world.launch = launchPower } }
    @Published var tableScale: Float = 6.0 { didSet { world.numDiePerSide = tableScale } }
    @Published var maxUndos: Int = 1 {
        didSet {
            world.numUndo = maxUndos
            if maxUndos == 0 { canUndo = false; canRedo = false }
        }
    }
    @Published var shakeToRoll: Bool = true {
        didSet { shakeToRoll ? startMotionUpdates() : stopMotionUpdates() }
    }

    private let motionManager = CMMotionManager()
    private var physicsObserver: NSObjectProtocol?
    private var timer: Timer?
    private var lastShakeTime: TimeInterval = 0
    private var tableSize = CGSize(width: 180, height: 220)
    private var isInitialDrop = true
    private var isRestoring = false
    private var hasRolled = false

    init() {
        let newWorld = World(size: CGRect(origin: .zero, size: CGSize(width: 180, height: 220)))
        newWorld.sound = false
        newWorld.numDiePerSide = 6.0
        newWorld.numUndo = 1
        newWorld.launchType = .scatter
        newWorld.launch = 1.0

        self.world = newWorld
        self.delegate = WatchSceneDelegate(world: newWorld)

        newWorld.onUndoRedoStateChanged = { [weak self] undo, redo in
            Task { @MainActor [weak self] in
                self?.canUndo = undo
                self?.canRedo = redo
            }
        }

        setupDice(type: .dice6, count: 2)

        physicsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("physicsDone"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePhysicsDone()
            }
        }
    }

    deinit {
        if let observer = physicsObserver { NotificationCenter.default.removeObserver(observer) }
        motionManager.stopAccelerometerUpdates()
        timer?.invalidate()
    }

    func updateSize(_ newSize: CGSize) {
        guard newSize.width > 0, newSize.height > 0, newSize != tableSize else { return }
        tableSize = newSize
        world.resize(to: CGRect(origin: .zero, size: newSize))
    }

    func count(for type: DieType) -> Int {
        world.dice.filter { $0.dieType == type }.count
    }

    func adjustDie(type: DieType, delta: Int) {
        guard !isRolling else { return }
        let currentTotal = world.dice.count
        if delta > 0 {
            guard currentTotal < 12 else { return }
            selectedType = type
            if let idx = DieType.allCases.firstIndex(of: type) { crownIndex = Double(idx) }
            let pos = CGPoint(
                x: CGFloat.random(in: 0.25...0.75) * tableSize.width,
                y: CGFloat.random(in: 0.25...0.75) * tableSize.height
            )
            world.addDie(pos, type: type)
        } else if delta < 0 {
            guard currentTotal > 1, let dieToRemove = world.dice.last(where: { $0.dieType == type }) else { return }
            world.destroyDie(dieToRemove)
            if let remainingType = world.dice.last?.dieType {
                selectedType = remainingType
                if let idx = DieType.allCases.firstIndex(of: remainingType) { crownIndex = Double(idx) }
            }
        }
        dieCount = world.dice.count
        isInitialDrop = true
        hasRolled = false
        world.deleteUndo()
        canUndo = false
        canRedo = false
        WKInterfaceDevice.current().play(.click)
        resultText = "Tap or shake"
    }

    func setupDice(type: DieType, count: Int) {
        timer?.invalidate()
        isRolling = false
        isInitialDrop = true
        isRestoring = false
        hasRolled = false

        selectedType = type
        dieCount = max(1, min(12, count))
        if let idx = DieType.allCases.firstIndex(of: type) { crownIndex = Double(idx) }

        world.deleteUndo()
        canUndo = false
        canRedo = false

        world.dice.forEach { world.destroyDie($0) }
        for _ in 0..<dieCount {
            let pos = CGPoint(
                x: CGFloat.random(in: 0.25...0.75) * tableSize.width,
                y: CGFloat.random(in: 0.25...0.75) * tableSize.height
            )
            world.addDie(pos, type: type)
        }
        world.unselectDie(die: nil)
        world.unholdDie(die: nil)
        resultText = "Tap or shake"
    }

    func handleCrownChange(_ index: Int) {
        let cases = DieType.allCases
        let newType = cases[((index % cases.count) + cases.count) % cases.count]
        guard newType != selectedType else { return }
        WKInterfaceDevice.current().play(.click)
        setupDice(type: newType, count: dieCount)
    }

    func changeCount(by delta: Int) {
        if delta > 0 {
            adjustDie(type: selectedType, delta: 1)
        } else if delta < 0, world.dice.count > 1, let lastDie = world.dice.last {
            adjustDie(type: lastDie.dieType, delta: -1)
        }
    }

    func handleTap(at location: CGPoint) {
        guard !isRolling else { return }
        if let die = world.nearestDie(pos: location, tolerance: 24), world.state == .rolled {
            world.holdDie(die)
            WKInterfaceDevice.current().play(.click)
        } else {
            rollDice(at: location)
        }
    }

    func handleDoubleTap(at location: CGPoint) {
        guard !isRolling, world.dice.count < 12 else { return }
        let typeToAdd = world.nearestDie(pos: location, tolerance: 28)?.dieType ?? selectedType
        selectedType = typeToAdd
        if let idx = DieType.allCases.firstIndex(of: typeToAdd) { crownIndex = Double(idx) }
        world.addDie(location, type: typeToAdd)
        dieCount = world.dice.count
        isInitialDrop = true
        hasRolled = false
        world.deleteUndo()
        canUndo = false
        canRedo = false
        WKInterfaceDevice.current().play(.click)
        resultText = "Tap or shake"
    }

    func rollDice(at point: CGPoint? = nil) {
        guard !isRolling, world.numToRoll() > 0 else { return }
        hasRolled = true
        beginPhysics(label: "Rolling...", restoring: false)
        WKInterfaceDevice.current().play(.click)
        let target = point ?? CGPoint(x: tableSize.width / 2, y: tableSize.height / 2)
        world.roll(target, false)
    }

    func undoRoll() {
        guard world.state == .rolled, canUndo, !isRolling else { return }
        hasRolled = true
        beginPhysics(label: "Undoing...", restoring: true)
        WKInterfaceDevice.current().play(.click)
        world.undo()
    }

    func redoRoll() {
        guard world.state == .rolled, canRedo, !isRolling else { return }
        hasRolled = true
        beginPhysics(label: "Redoing...", restoring: true)
        WKInterfaceDevice.current().play(.click)
        world.redo()
    }

    private func beginPhysics(label: String, restoring: Bool) {
        timer?.invalidate()
        isRolling = true
        isInitialDrop = false
        isRestoring = restoring
        resultText = label

        world.isPaused = false
        world.dice.forEach { $0.isPaused = false }

        timer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRolling else { return }
                self.handlePhysicsDone()
            }
        }
    }

    private func handlePhysicsDone() {
        timer?.invalidate()
        isRolling = false
        dieCount = max(1, world.dice.count)
        if let lastType = world.dice.last?.dieType {
            selectedType = lastType
        }

        if isInitialDrop {
            isInitialDrop = false
            world.deleteUndo()
            world.newUndo()
        } else if !isRestoring {
            world.newUndo()
        }
        isRestoring = false

        WKInterfaceDevice.current().play(.click)
        if hasRolled {
            updateResultLabel()
        } else {
            resultText = "Tap or shake"
        }

        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.world.freeze()
            }
        }
    }

    private func updateResultLabel() {
        let results = world.resultDice().sorted(by: >)
        guard !results.isEmpty else { resultText = "No dice"; return }

        let allCoins = !world.dice.isEmpty && world.dice.allSatisfy { $0.dieType == .dice2 }
        if allCoins {
            let heads = results.filter { $0 == 1 }.count
            resultText = "H: \(heads)  T: \(results.count - heads)"
        } else if results.count == 1 {
            resultText = "\(results[0])"
        } else {
            resultText = "\(results.reduce(0, +)) (\(results.map(String.init).joined(separator: ", ")))"
        }
    }

    // MARK: - Wrist Shake Detection

    func startMotionUpdates() {
        guard shakeToRoll, motionManager.isAccelerometerAvailable, !motionManager.isAccelerometerActive else { return }
        motionManager.accelerometerUpdateInterval = 0.08
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let acc = data?.acceleration else { return }
            let mag = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
            let now = ProcessInfo.processInfo.systemUptime
            if mag > 2.3 {
                Task { @MainActor [weak self] in
                    guard let self, self.shakeToRoll, now - self.lastShakeTime > 1.0, !self.isRolling else { return }
                    self.lastShakeTime = now
                    self.rollDice()
                }
            }
        }
    }

    func stopMotionUpdates() {
        if motionManager.isAccelerometerActive { motionManager.stopAccelerometerUpdates() }
    }

    func label(for type: DieType) -> String {
        switch type {
        case .dice2:  return "Coin"
        case .dice4:  return "d4"
        case .dice6:  return "d6"
        case .dice8:  return "d8"
        case .dice10: return "d10"
        case .dice12: return "d12"
        case .dice20: return "d20"
        }
    }
}

// MARK: - Watch Settings Sheet

struct WatchSettingsView: View {
    @ObservedObject var controller: WatchDiceController

    private let undoOptions: [(label: String, value: Int)] = [
        ("Off", 0), ("1", 1), ("3", 3), ("5", 5), ("∞", -1)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Dice Mix (\(controller.dieCount)/12)") {
                    ForEach(DieType.allCases, id: \.self) { type in
                        let typeCount = controller.count(for: type)
                        HStack {
                            Text(controller.label(for: type))
                            Spacer()
                            Button {
                                controller.adjustDie(type: type, delta: -1)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.body)
                            }
                            .buttonStyle(.borderless)
                            .disabled(typeCount == 0 || controller.dieCount <= 1)

                            Text("\(typeCount)")
                                .monospacedDigit()
                                .frame(minWidth: 20)

                            Button {
                                controller.adjustDie(type: type, delta: 1)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.body)
                            }
                            .buttonStyle(.borderless)
                            .disabled(controller.dieCount >= 12)
                        }
                    }
                }

                Section("Throw & Table") {
                    Picker("Formation", selection: $controller.launchType) {
                        Text("Scatter").tag(LaunchType.scatter)
                        Text("Gather").tag(LaunchType.gather)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Power: \(String(format: "%.1fx", controller.launchPower))").font(.caption2)
                        Slider(value: $controller.launchPower, in: 0.5...1.5, step: 0.1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Table Zoom: \(Int(controller.tableScale))").font(.caption2)
                        Slider(value: $controller.tableScale, in: 4...10, step: 1)
                    }
                }

                Section("Controls & Audio") {
                    Toggle("Sound Effects", isOn: $controller.isSoundOn)
                    Toggle("Shake to Roll", isOn: $controller.shakeToRoll)

                    Picker("Max Undos", selection: $controller.maxUndos) {
                        ForEach(undoOptions, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Main watchOS SwiftUI View

struct WatchGameView: View {
    @StateObject private var controller = WatchDiceController()
    @FocusState private var isCrownFocused: Bool
    @State private var showingSettings = false

    private var activeDiceLabel: String {
        let types = Set(controller.world.dice.map(\.dieType))
        if types.count > 1 {
            return "\(controller.dieCount) mix"
        }
        return "\(controller.dieCount)\(controller.label(for: controller.selectedType))"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Hidden Digital Crown receiver so .focusable never steals table taps
                Color.clear
                    .frame(width: 1, height: 1)
                    .focusable(true)
                    .focused($isCrownFocused)
                    .digitalCrownRotation(
                        $controller.crownIndex,
                        from: 0,
                        through: Double(DieType.allCases.count - 1),
                        by: 1,
                        sensitivity: .medium,
                        isContinuous: true,
                        isHapticFeedbackEnabled: false
                    )
                    .onChange(of: Int(controller.crownIndex.rounded())) { _, idx in
                        controller.handleCrownChange(idx)
                    }

                // Full-screen 3D Physics Dice Table
                SceneView(
                    scene: controller.world,
                    options: [.rendersContinuously],
                    delegate: controller.delegate
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Transparent tap & double-tap catcher above SceneView
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        controller.handleDoubleTap(at: location)
                        isCrownFocused = true
                    }
                    .onTapGesture(count: 1) { location in
                        controller.handleTap(at: location)
                        isCrownFocused = true
                    }

                // Minimal, unobtrusive HUD overlay so dice remain visible underneath
                VStack {
                    HStack(spacing: 6) {
                        hudButton(
                            systemName: controller.isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill",
                            tint: controller.isSoundOn ? .green : .white.opacity(0.75)
                        ) {
                            controller.isSoundOn.toggle()
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            hudButton(systemName: "minus", disabled: controller.dieCount <= 1) {
                                controller.changeCount(by: -1)
                            }

                            Text(activeDiceLabel)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black, radius: 2)

                            hudButton(systemName: "plus", disabled: controller.dieCount >= 12) {
                                controller.changeCount(by: 1)
                            }
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            if controller.canUndo {
                                hudButton(systemName: "arrow.uturn.backward", disabled: controller.isRolling) {
                                    controller.undoRoll()
                                }
                            }
                            if controller.canRedo {
                                hudButton(systemName: "arrow.uturn.forward", disabled: controller.isRolling) {
                                    controller.redoRoll()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    Spacer()

                    HStack(alignment: .bottom) {
                        Text(controller.resultText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .shadow(color: .black, radius: 2)
                            .allowsHitTesting(false)

                        Spacer()

                        Button {
                            isCrownFocused = false
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .shadow(color: .black, radius: 2)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
                }
            }
            .sheet(isPresented: $showingSettings, onDismiss: {
                isCrownFocused = true
            }) {
                WatchSettingsView(controller: controller)
            }
            .onAppear {
                isCrownFocused = true
                controller.updateSize(geo.size)
                controller.startMotionUpdates()
            }
            .onChange(of: geo.size) { _, newSize in
                controller.updateSize(newSize)
            }
            .onDisappear {
                controller.stopMotionUpdates()
            }
        }
    }

    @ViewBuilder
    private func hudButton(
        systemName: String,
        tint: Color = .white.opacity(0.85),
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(disabled ? .white.opacity(0.25) : tint)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .shadow(color: .black, radius: 2)
    }
}

#Preview {
    WatchGameView()
}
