//
//  DiceShortcuts.swift
//  dice
//

@preconcurrency import AppIntents
import UIKit
import SceneKit

// MARK: - 1. Shortcut Parameter Enums

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
enum ShortcutDieType: String, AppEnum {
    case d2, d4, d6, d8, d10, d12, d20

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Die Type")
    static var caseDisplayRepresentations: [ShortcutDieType: DisplayRepresentation] = [
        .d2: "Coin (d2)",
        .d4: "d4 (Tetrahedron)",
        .d6: "d6 (Cube)",
        .d8: "d8 (Octahedron)",
        .d10: "d10 (Decahedron)",
        .d12: "d12 (Dodecahedron)",
        .d20: "d20 (Icosahedron)"
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
        .tap: "Tap",
        .swipe: "Swipe"
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

// MARK: - 2. Physics-to-Shortcuts Bridge

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
@MainActor
final class DiceShortcutBridge {
    static let shared = DiceShortcutBridge()
    weak var game: Game?
    weak var viewController: GameViewController?

    func register(viewController: GameViewController, game: Game) {
        self.viewController = viewController
        self.game = game
    }

    func prepareTableIfNeeded() async -> Game? {
        for _ in 0..<25 where game == nil {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard let game = game else { return nil }

        if let vc = viewController,
           vc.startView != nil || vc.settingView != nil || vc.diceNumberView != nil ||
           vc.diceSetView != nil || vc.helpView != nil || vc.helpDetailView != nil || vc.historyView != nil {
            vc.donePressed(sender: nil)
        }
        return game
    }

    func waitForPhysicsSettle(trigger: () -> Void) async -> [Int] {
        let stream = NotificationCenter.default.notifications(named: NSNotification.Name("physicsDone"))
        trigger()
        for await _ in stream {
            return game?.world_.resultDice() ?? []
        }
        return []
    }

    /// Executes a physical throw matching the UI's Tap or Swipe (speed + curl) mechanics
    func performThrow(
        method: ShortcutThrowMethod,
        energy: Double,
        curl: Double,
        formation: ShortcutLaunchMode
    ) async -> [Int] {
        guard let game = await prepareTableIfNeeded() else { return [] }
        let world = game.world_

        guard world.numToRoll() > 0 else {
            return world.resultDice()
        }

        let toggleFormation: Bool
        switch formation {
        case .currentSetting: toggleFormation = false
        case .gathered: toggleFormation = (world.launchType != .gather)
        case .scattered: toggleFormation = (world.launchType == .scatter)
        }
        
        // if (_launchType == .gather && !toggle) || (_launchType == .scatter && toggle)

        return await waitForPhysicsSettle {
            
            switch method {
            case .tap:
                game.hud?.toRoll()
                game.timerPhysics?.invalidate()
                world.roll(toggleFormation)
                //let angle = Float(min(1.0, max(0.0, curl)) * 2.0 * .pi)
                //world.roll(toggleFormation, angle)
                world.roll(toggleFormation, 0.0)

            case .swipe:
                let angle = CGFloat(min(1.0, max(0.0, curl)) * 2.0 * .pi)
                let speed = CGFloat(200.0 + min(1.0, max(0.0, energy)) * 3800.0)
                let direction = CGFloat.random(in: 0...(2.0 * .pi))
                let velocity = CGPoint(x: speed * cos(direction), y: speed * sin(direction))
                let centerScreen = world.convert(pos: simd_float3(0, 0, 0))

                game.flicked(velocity, pos: centerScreen, speed: speed, angle: angle, toggleFormation)
            }
        }
    }
}

// MARK: - 3. App Intents

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct ThrowDiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Throw Dice"
    static var description = IntentDescription("Throws the active dice on the table using a tap or swipe gesture.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Method", default: .swipe)
    var method: ShortcutThrowMethod

    @Parameter(title: "Swipe Speed (0 = Gentle, 1 = Fast)", default: 0.5, controlStyle: .slider, inclusiveRange: (0.0, 1.0))
    var energy: Double

    @Parameter(title: "Swipe Curl (0 = Straight, 1 = Spin)", default: 0.2, controlStyle: .slider, inclusiveRange: (0.0, 1.0))
    var curl: Double

    @Parameter(title: "Formation", default: .currentSetting)
    var formation: ShortcutLaunchMode

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        let results = await DiceShortcutBridge.shared.performThrow(
            method: method,
            energy: energy,
            curl: curl,
            formation: formation
        )
        return .result(value: results)
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct ReplaceDiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Dice on Table"
    static var description = IntentDescription("Replaces all dice on the table with a specific type and count.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Die Type", default: .d6)
    var dieType: ShortcutDieType

    @Parameter(title: "Count", default: 2, inclusiveRange: (1, 100))
    var count: Int

    @Parameter(title: "Throw Immediately", default: true)
    var throwNow: Bool

    @Parameter(title: "Method", default: .swipe)
    var method: ShortcutThrowMethod

    @Parameter(title: "Swipe Speed (0 = Gentle, 1 = Fast)", default: 0.5, controlStyle: .slider, inclusiveRange: (0.0, 1.0))
    var energy: Double

    @Parameter(title: "Swipe Curl (0 = Straight, 1 = Spin)", default: 0.2, controlStyle: .slider, inclusiveRange: (0.0, 1.0))
    var curl: Double

    @Parameter(title: "Formation", default: .currentSetting)
    var formation: ShortcutLaunchMode

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.prepareTableIfNeeded() else {
            return .result(value: [])
        }
        game.setDiceNumber(diceSet: [dieType.toDieType: count])

        let results: [Int]
        if throwNow {
            results = await DiceShortcutBridge.shared.performThrow(
                method: method,
                energy: energy,
                curl: curl,
                formation: formation
            )
        } else {
            results = game.world_.resultDice()
        }
        return .result(value: results)
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct AddDiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Dice to Table"
    static var description = IntentDescription("Adds more dice of a chosen type to the existing dice on the table.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Die Type", default: .d6)
    var dieType: ShortcutDieType

    @Parameter(title: "Count", default: 1, inclusiveRange: (1, 50))
    var count: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.prepareTableIfNeeded() else {
            return .result(value: [])
        }
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
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.prepareTableIfNeeded() else {
            return .result(value: [])
        }
        guard game.world_.undoButton.isEnabled else {
            return .result(value: game.world_.resultDice())
        }
        let results = await DiceShortcutBridge.shared.waitForPhysicsSettle {
            game.undo()
        }
        return .result(value: results)
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct RedoRollIntent: AppIntent {
    static var title: LocalizedStringResource = "Redo Roll"
    static var description = IntentDescription("Restores the previously undone dice roll.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.prepareTableIfNeeded() else {
            return .result(value: [])
        }
        guard game.world_.redoButton.isEnabled else {
            return .result(value: game.world_.resultDice())
        }
        let results = await DiceShortcutBridge.shared.waitForPhysicsSettle {
            game.redo()
        }
        return .result(value: results)
    }
}

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct GetDiceResultsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Dice Results"
    static var description = IntentDescription("Reads the current face-up values of all dice on the table.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let game = await DiceShortcutBridge.shared.prepareTableIfNeeded() else {
            return .result(value: [])
        }
        return .result(value: game.world_.resultDice())
    }
}

// MARK: - 4. Pre-built Siri & Shortcuts Phrases

@available(iOS 16.0, macOS 13.0, visionOS 1.0, *)
struct DiceAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ThrowDiceIntent(),
            phrases: [
                "Throw dice in \(.applicationName)",
                "Roll the dice in \(.applicationName)"
            ],
            shortTitle: "Throw Dice",
            systemImageName: "dice.fill"
        )
        AppShortcut(
            intent: ReplaceDiceIntent(),
            phrases: [
                "Roll \(\.$dieType) in \(.applicationName)"
            ],
            shortTitle: "Set & Throw Dice",
            systemImageName: "die.face.6.fill"
        )
    }
}
