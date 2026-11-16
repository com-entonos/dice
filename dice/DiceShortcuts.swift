//
//  DiceShortcuts.swift
//  dice
//

@preconcurrency import AppIntents
import UIKit
import SceneKit

// MARK: - Shortcut Parameter Enums

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
enum ShortcutDieType: String, AppEnum {
    case d2, d4, d6, d8, d10, d12, d20

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Die Type")
    static var caseDisplayRepresentations: [ShortcutDieType: DisplayRepresentation] = [
        .d2: "Coin (d2)", .d4: "d4 (Tetrahedron)", .d6: "d6 (Cube)",
        .d8: "d8 (Octahedron)", .d10: "d10 (Decahedron)",
        .d12: "d12 (Dodecahedron)", .d20: "d20 (Icosahedron)"
    ]

    var toDieType: DieType {
        switch self {
        case .d2: return .dice2
        case .d4: return .dice4
        case .d6: return .dice6
        case .d8: return .dice8
        case .d10: return .dice10
        case .d12: return .dice12
        case .d20: return .dice20
        }
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
enum ShortcutThrowMethod: String, AppEnum {
    case tap, swipe

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Throw Method")
    static var caseDisplayRepresentations: [ShortcutThrowMethod: DisplayRepresentation] = [
        .tap: "Tap", .swipe: "Swipe"
    ]
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
enum ShortcutLaunchMode: String, AppEnum {
    case currentSetting, gathered, scattered

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Formation")
    static var caseDisplayRepresentations: [ShortcutLaunchMode: DisplayRepresentation] = [
        .currentSetting: "Default (Current Setting)",
        .gathered: "Gathered",
        .scattered: "Scattered"
    ]
}

// MARK: - Physics-to-Shortcuts Bridge

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
@MainActor
final class DiceShortcutBridge {
    static let shared = DiceShortcutBridge()
    weak var game: Game?
    weak var viewController: GameViewController?

    private var continuation: CheckedContinuation<[Int], Never>?
    private var observer: NSObjectProtocol?
    private var idleRestoreTask: Task<Void, Never>?

    private init() {
        // Persistent observer avoids unbounded AsyncStream buffering across long Shortcut loops.
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("physicsDone"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let cont = self.continuation, self.game?.world_.state != .rolling else { return }
                self.continuation = nil
                cont.resume(returning: self.game?.world_.resultDice() ?? [])
            }
        }
    }

    func register(viewController: GameViewController, game: Game) {
        self.viewController = viewController
        self.game = game
    }

    /// Prevents iPhone/iPad Auto-Lock from suspending SceneKit mid-loop; leaves Mac and visionOS untouched.
    private func keepScreenAwakeIfNeeded() {
        let idiom = UIDevice.current.userInterfaceIdiom
        guard !ProcessInfo.processInfo.isiOSAppOnMac, idiom == .phone || idiom == .pad else { return }

        UIApplication.shared.isIdleTimerDisabled = true
        idleRestoreTask?.cancel()
        idleRestoreTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    /// Ensures the 3D table is loaded, active on iOS/iPadOS if needed, and idle before running an intent.
    func readyGame<I: AppIntent>(for intent: I) async -> Game? {
        if game == nil { try? await Task.sleep(nanoseconds: 150_000_000) }

        let isMac = ProcessInfo.processInfo.isiOSAppOnMac
        let needsOpen = (game == nil) || (!isMac && UIApplication.shared.applicationState != .active)
        if needsOpen, #available(iOS 26.0, macOS 26.0, visionOS 26.0, *), intent.systemContext.currentMode.canContinueInForeground {
            try? await intent.continueInForeground(alwaysConfirm: false)
        }

        for _ in 0..<30 where game == nil { try? await Task.sleep(nanoseconds: 100_000_000) }
        guard let game else { return nil }

        // Dismiss any open modal sheet so the table is ready for physics.
        if let vc = viewController,
           vc.startView != nil || vc.settingView != nil || vc.diceNumberView != nil ||
           vc.diceSetView != nil || vc.helpView != nil || vc.helpDetailView != nil || vc.historyView != nil {
            vc.donePressed(sender: nil)
        }

        // Wait for any in-flight roll to finish before starting a new command.
        for _ in 0..<50 where game.world_.state == .rolling { try? await Task.sleep(nanoseconds: 50_000_000) }
        return game
    }

    /// Suspends until SceneKit posts "physicsDone" and settles post-roll HUD/audio state.
    func runAndSettle(_ action: () -> Void) async -> [Int] {
        keepScreenAwakeIfNeeded()

        if let stale = continuation {
            continuation = nil
            stale.resume(returning: game?.world_.resultDice() ?? [])
        }

        let results = await withCheckedContinuation { cont in
            continuation = cont
            action()
            if let world = game?.world_, world.state != .rolling {
                continuation = nil
                cont.resume(returning: world.resultDice())
            }
        }

        try? await Task.sleep(nanoseconds: 30_000_000)
        return results
    }

    /// Simulates a human tap or swipe inside the central 50% of the table while honoring game rules (canThrow).
    func throwDice(game: Game, method: ShortcutThrowMethod, energy: Double, curl: Double, formation: ShortcutLaunchMode) async -> [Int] {
        let world = game.world_
        guard world.numToRoll() > 0, game.canThrow_ else { return world.resultDice() }

        let toggle = switch formation {
        case .currentSetting: false
        case .gathered: world.launchType != .gather
        case .scattered: world.launchType != .scatter
        }

        let tableSize = game.tableSize_
        let touchPos = CGPoint(
            x: CGFloat.random(in: 0.25...0.75) * tableSize.width,
            y: CGFloat.random(in: 0.25...0.75) * tableSize.height
        )

        return await runAndSettle {
            game.timerPhysics?.invalidate()
            switch method {
            case .tap:
                game.hud?.toRoll()
                world.roll(touchPos, toggle)
            case .swipe:
                let speed = CGFloat(200.0 + min(1.0, max(0.0, energy)) * 3800.0)
                let angle = CGFloat(min(1.0, max(0.0, curl)) * 2.0 * .pi)
                let dir = CGFloat.random(in: 0...(2.0 * .pi))
                let vel = CGPoint(x: speed * cos(dir), y: speed * sin(dir))
                game.flicked(vel, pos: touchPos, speed: speed, angle: angle, toggle)
            }
        }
    }
}

// MARK: - App Intents

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct ThrowDiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Throw Dice"
    static var description = IntentDescription("Throws the active dice on the table using a tap or swipe gesture.")
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @Parameter(title: "Method", default: .swipe) var method: ShortcutThrowMethod
    @Parameter(title: "Swipe Speed (0 = Gentle, 1 = Fast)", default: 0.5, controlStyle: .slider, inclusiveRange: (0.0, 1.0)) var energy: Double
    @Parameter(title: "Swipe Curl (0 = Straight, 1 = Spin)", default: 0.2, controlStyle: .slider, inclusiveRange: (0.0, 1.0)) var curl: Double
    @Parameter(title: "Formation", default: .currentSetting) var formation: ShortcutLaunchMode

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.readyGame(for: self) else { return .result(value: []) }
        return .result(value: await DiceShortcutBridge.shared.throwDice(game: game, method: method, energy: energy, curl: curl, formation: formation))
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct ReplaceDiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Dice on Table"
    static var description = IntentDescription("Replaces all dice on the table with a specific type and count.")
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @Parameter(title: "Die Type", default: .d6) var dieType: ShortcutDieType
    @Parameter(title: "Count", default: 2, inclusiveRange: (1, 100)) var count: Int
    @Parameter(title: "Throw Immediately", default: true) var throwNow: Bool
    @Parameter(title: "Method", default: .swipe) var method: ShortcutThrowMethod
    @Parameter(title: "Swipe Speed (0 = Gentle, 1 = Fast)", default: 0.5, controlStyle: .slider, inclusiveRange: (0.0, 1.0)) var energy: Double
    @Parameter(title: "Swipe Curl (0 = Straight, 1 = Spin)", default: 0.2, controlStyle: .slider, inclusiveRange: (0.0, 1.0)) var curl: Double
    @Parameter(title: "Formation", default: .currentSetting) var formation: ShortcutLaunchMode

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.readyGame(for: self) else { return .result(value: []) }
        game.setDiceNumber(diceSet: [dieType.toDieType: count])
        let results = throwNow
            ? await DiceShortcutBridge.shared.throwDice(game: game, method: method, energy: energy, curl: curl, formation: formation)
            : game.world_.resultDice()
        return .result(value: results)
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct AddDiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Dice to Table"
    static var description = IntentDescription("Adds more dice of a chosen type to the existing dice on the table.")
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @Parameter(title: "Die Type", default: .d6) var dieType: ShortcutDieType
    @Parameter(title: "Count", default: 1, inclusiveRange: (1, 50)) var count: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.readyGame(for: self) else { return .result(value: []) }
        var inv = game.world_.inventory()
        inv[dieType.toDieType, default: 0] += count
        game.setDiceNumber(diceSet: inv)
        return .result(value: game.world_.resultDice())
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct UndoRollIntent: AppIntent {
    static var title: LocalizedStringResource = "Undo Roll"
    static var description = IntentDescription("Reverts the dice on the table to their previous roll.")
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.readyGame(for: self) else { return .result(value: []) }
        guard game.world_.state == .rolled, game.world_.undoButton.isEnabled else { return .result(value: game.world_.resultDice()) }
        return .result(value: await DiceShortcutBridge.shared.runAndSettle { game.undo() })
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct RedoRollIntent: AppIntent {
    static var title: LocalizedStringResource = "Redo Roll"
    static var description = IntentDescription("Restores the previously undone dice roll.")
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.readyGame(for: self) else { return .result(value: []) }
        guard game.world_.state == .rolled, game.world_.redoButton.isEnabled else { return .result(value: game.world_.resultDice()) }
        return .result(value: await DiceShortcutBridge.shared.runAndSettle { game.redo() })
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct GetDiceResultsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Dice Results"
    static var description = IntentDescription("Reads the current face-up values of all dice on the table.")
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.readyGame(for: self) else { return .result(value: []) }
        return .result(value: game.world_.resultDice())
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct DiceAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ThrowDiceIntent(),
            phrases: ["Throw dice in \(.applicationName)", "Roll the dice in \(.applicationName)"],
            shortTitle: "Throw Dice",
            systemImageName: "dice.fill"
        )
        AppShortcut(
            intent: ReplaceDiceIntent(),
            phrases: ["Roll \(\.$dieType) in \(.applicationName)"],
            shortTitle: "Set & Throw Dice",
            systemImageName: "die.face.6.fill"
        )
    }
}
