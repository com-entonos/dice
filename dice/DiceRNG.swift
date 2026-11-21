//
//  DiceRNG.swift
//  dice
//
//  Created by G.J. Parker on 11/20/26.
//  Copyright © 2026 G.J. Parker. All rights reserved.
//
import Foundation
import CoreGraphics
#if canImport(GameplayKit)
import GameplayKit
#endif

/// Thread-safe random number generator wrapper that defaults to Apple's hardware-seeded
/// `SystemRandomNumberGenerator` (ChaCha20 CSPRNG) and can switch to a deterministic
/// seeded generator (`GKMersenneTwisterRandomSource` on iOS/macOS/visionOS, `SplitMix64`
/// fallback on watchOS) for reproducible physics testing.
enum DiceRNG {
    private static let lock = NSLock()
    private static var system = SystemRandomNumberGenerator()
    private static var seeded: SeededStream?

    /// Reverts to Apple's default hardware-seeded `SystemRandomNumberGenerator`.
    static func useSystemDefault() {
        lock.lock()
        defer { lock.unlock() }
        seeded = nil
    }

    /// Switches to a deterministic stream starting at `seed`.
    static func useSeed(_ seed: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        seeded = SeededStream(seed: seed)
    }

    static var isSeeded: Bool {
        lock.lock()
        defer { lock.unlock() }
        return seeded != nil
    }

    // MARK: - Float

    static func float(in range: ClosedRange<Float>) -> Float {
        lock.lock()
        defer { lock.unlock() }
        if seeded != nil {
            return Float.random(in: range, using: &seeded!)
        }
        return Float.random(in: range, using: &system)
    }

    static func float(in range: Range<Float>) -> Float {
        lock.lock()
        defer { lock.unlock() }
        if seeded != nil {
            return Float.random(in: range, using: &seeded!)
        }
        return Float.random(in: range, using: &system)
    }

    // MARK: - CGFloat

    static func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        lock.lock()
        defer { lock.unlock() }
        if seeded != nil {
            return CGFloat.random(in: range, using: &seeded!)
        }
        return CGFloat.random(in: range, using: &system)
    }

    static func cgFloat(in range: Range<CGFloat>) -> CGFloat {
        lock.lock()
        defer { lock.unlock() }
        if seeded != nil {
            return CGFloat.random(in: range, using: &seeded!)
        }
        return CGFloat.random(in: range, using: &system)
    }

    // MARK: - Int

    static func int(in range: ClosedRange<Int>) -> Int {
        lock.lock()
        defer { lock.unlock() }
        if seeded != nil {
            return Int.random(in: range, using: &seeded!)
        }
        return Int.random(in: range, using: &system)
    }

    static func int(in range: Range<Int>) -> Int {
        lock.lock()
        defer { lock.unlock() }
        if seeded != nil {
            return Int.random(in: range, using: &seeded!)
        }
        return Int.random(in: range, using: &system)
    }
}

// MARK: - Deterministic Seeded Stream

private struct SeededStream: RandomNumberGenerator {
    #if canImport(GameplayKit)
    private let source: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        self.source = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        let high = UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: source.nextInt())))
        let low = UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: source.nextInt())))
        return (high << 32) | low
    }
    #else
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
    #endif
}
