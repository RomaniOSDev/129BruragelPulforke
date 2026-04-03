//
//  BlitzDashViewModel.swift
//  129BruragelPulforke
//

import Combine
import CoreGraphics
import Foundation
import SwiftUI

@MainActor
final class BlitzDashViewModel: ObservableObject {
    enum Phase: Equatable {
        case ready
        case playing
        case won
        case lost
    }

    struct Orb: Identifiable {
        let id = UUID()
        var center: CGPoint
        var collected: Bool
    }

    struct Hazard: Identifiable {
        let id = UUID()
        var center: CGPoint
        var size: CGSize
        var velocity: CGVector
    }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var player: CGPoint = .init(x: 0.12, y: 0.82)
    @Published private(set) var score: Int = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var hazards: [Hazard] = []
    @Published private(set) var orbs: [Orb] = []
    @Published private(set) var orbsCollected: Int = 0

    private(set) var direction: CGVector = .init(dx: 1, dy: 0)
    private var lastTick: Date?
    private var ticker: AnyCancellable?

    let level: Int
    let difficulty: Difficulty

    private let goal = CGRect(x: 0.72, y: 0.06, width: 0.2, height: 0.14)
    private let playerRadius: CGFloat = 0.035
    /// Normalized-space circle; hazards must not intersect this or the player dies on frame 1.
    private var spawnShield: CGRect {
        let pad = playerRadius * 2.8
        let c = player
        return CGRect(x: c.x - pad, y: c.y - pad, width: pad * 2, height: pad * 2)
    }

    init(level: Int, difficulty: Difficulty) {
        self.level = level
        self.difficulty = difficulty
    }

    func prepareArena() {
        phase = .ready
        elapsed = 0
        score = 0
        orbsCollected = 0
        player = CGPoint(x: 0.12, y: 0.82)
        direction = CGVector(dx: 1, dy: 0)
        buildHazards()
        buildOrbs()
    }

    func startRun() {
        guard phase == .ready else { return }
        phase = .playing
        lastTick = Date()
        ticker?.cancel()
        ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.step()
            }
    }

    func stopLoop() {
        ticker?.cancel()
        ticker = nil
    }

    func handleSwipe(translation: CGSize) {
        guard phase == .playing else { return }
        let dx = translation.width
        let dy = translation.height
        guard hypot(dx, dy) > 18 else { return }
        if abs(dx) > abs(dy) {
            direction = CGVector(dx: dx > 0 ? 1 : -1, dy: 0)
        } else {
            direction = CGVector(dx: 0, dy: dy > 0 ? 1 : -1)
        }
    }

    private func buildHazards() {
        let baseCount = 2 + level
        let count = max(3, min(10, baseCount))
        var items: [Hazard] = []
        let speed = 0.12 * difficulty.obstacleSpeedMultiplier * (1 + CGFloat(level) * 0.04)
        let shield = spawnShield
        let goalPad = goal.insetBy(dx: -0.04, dy: -0.04)

        for i in 0..<count {
            let horizontal = i % 2 == 0
            let t = CGFloat(i) / CGFloat(max(1, count - 1))
            var cx = horizontal ? 0.28 + 0.44 * t : 0.22 + 0.055 * CGFloat(i)
            var cy = horizontal ? 0.22 + 0.38 * t : 0.24 + t * 0.5
            if horizontal {
                cy = max(0.2, min(0.58, cy))
                cx = max(0.22, min(0.78, cx))
            } else {
                cx = max(0.18, min(0.72, cx))
                cy = max(0.22, min(0.72, cy))
            }
            let vel: CGVector
            if horizontal {
                vel = CGVector(dx: i % 3 == 0 ? speed : -speed, dy: 0)
            } else {
                vel = CGVector(dx: 0, dy: i % 3 == 0 ? speed : -speed)
            }
            var hazard = Hazard(
                center: CGPoint(x: cx, y: cy),
                size: CGSize(width: horizontal ? 0.14 : 0.055, height: horizontal ? 0.055 : 0.14),
                velocity: vel
            )
            var tries = 0
            while tries < 12 && (hazardHitRect(hazard).intersects(shield) || hazardHitRect(hazard).intersects(goalPad)) {
                tries += 1
                cx += 0.06 * CGFloat(tries % 3 - 1)
                cy -= 0.05 * CGFloat((tries / 3) + 1)
                cx = min(max(cx, 0.15), 0.85)
                cy = min(max(cy, 0.18), 0.7)
                hazard = Hazard(center: CGPoint(x: cx, y: cy), size: hazard.size, velocity: hazard.velocity)
            }
            if !hazardHitRect(hazard).intersects(shield), !hazardHitRect(hazard).intersects(goalPad) {
                items.append(hazard)
            }
        }
        if items.count < 2 {
            items = fallbackHazards(speed: speed, shield: shield, goalPad: goalPad)
        }
        hazards = items
    }

    private func hazardHitRect(_ h: Hazard) -> CGRect {
        CGRect(
            x: h.center.x - h.size.width / 2,
            y: h.center.y - h.size.height / 2,
            width: h.size.width,
            height: h.size.height
        ).insetBy(dx: -playerRadius * 0.9, dy: -playerRadius * 0.9)
    }

    private func fallbackHazards(speed: CGFloat, shield: CGRect, goalPad: CGRect) -> [Hazard] {
        let seeds: [(CGFloat, CGFloat, Bool)] = [
            (0.5, 0.35, true),
            (0.42, 0.52, false),
            (0.62, 0.45, true),
        ]
        var out: [Hazard] = []
        for (idx, s) in seeds.enumerated() {
            let horizontal = s.2
            let vel = horizontal
                ? CGVector(dx: idx % 2 == 0 ? speed : -speed, dy: 0)
                : CGVector(dx: 0, dy: idx % 2 == 0 ? speed : -speed)
            let hz = Hazard(
                center: CGPoint(x: s.0, y: s.1),
                size: CGSize(width: horizontal ? 0.12 : 0.05, height: horizontal ? 0.05 : 0.12),
                velocity: vel
            )
            if !hazardHitRect(hz).intersects(shield), !hazardHitRect(hz).intersects(goalPad) {
                out.append(hz)
            }
        }
        return out.isEmpty ? [
            Hazard(
                center: CGPoint(x: 0.55, y: 0.4),
                size: CGSize(width: 0.12, height: 0.05),
                velocity: CGVector(dx: speed, dy: 0)
            ),
        ] : out
    }

    private func buildOrbs() {
        var items: [Orb] = []
        for i in 0..<(2 + level / 2) {
            let c = CGPoint(x: 0.25 + CGFloat(i) * 0.08, y: 0.35 + CGFloat(i % 2) * 0.2)
            items.append(Orb(center: c, collected: false))
        }
        orbs = items
    }

    private func step() {
        guard phase == .playing else { return }
        let now = Date()
        let dt = lastTick.map { now.timeIntervalSince($0) } ?? 0.016
        lastTick = now
        elapsed += dt

        let moveSpeed = Double(0.18 * difficulty.obstacleSpeedMultiplier * (1.0 + 0.07 * Double(level)))
        let dx = direction.dx * moveSpeed * dt
        let dy = direction.dy * moveSpeed * dt
        var next = CGPoint(x: player.x + CGFloat(dx), y: player.y + CGFloat(dy))
        next.x = min(max(next.x, playerRadius + 0.02), 1 - playerRadius - 0.02)
        next.y = min(max(next.y, playerRadius + 0.02), 1 - playerRadius - 0.02)
        player = next

        var nextHazards = hazards
        for i in nextHazards.indices {
            var h = nextHazards[i]
            var c = h.center
            c.x += CGFloat(h.velocity.dx * dt * 60) * 0.0055
            c.y += CGFloat(h.velocity.dy * dt * 60) * 0.0055
            if c.x < 0.08 || c.x > 0.92 { h.velocity.dx *= -1 }
            if c.y < 0.12 || c.y > 0.9 { h.velocity.dy *= -1 }
            h.center = c
            nextHazards[i] = h
        }
        hazards = nextHazards

        var nextOrbs = orbs
        for i in nextOrbs.indices where !nextOrbs[i].collected {
            let d = hypot(nextOrbs[i].center.x - player.x, nextOrbs[i].center.y - player.y)
            if d < playerRadius + 0.03 {
                nextOrbs[i].collected = true
                orbsCollected += 1
                score += 25
            }
        }
        orbs = nextOrbs

        if intersectsHazards() {
            finish(loss: true)
            return
        }

        let gc = CGPoint(x: goal.midX, y: goal.midY)
        if hypot(player.x - gc.x, player.y - gc.y) < 0.065 {
            score += 120 + level * 10
            finish(loss: false)
            return
        }

        if elapsed > 95 {
            finish(loss: true)
        }
    }

    private func intersectsHazards() -> Bool {
        for h in hazards {
            let rect = CGRect(
                x: h.center.x - h.size.width / 2,
                y: h.center.y - h.size.height / 2,
                width: h.size.width,
                height: h.size.height
            ).insetBy(dx: -playerRadius * 0.9, dy: -playerRadius * 0.9)
            let pcircle = CGRect(x: player.x - playerRadius, y: player.y - playerRadius, width: playerRadius * 2, height: playerRadius * 2)
            if rect.intersects(pcircle) { return true }
        }
        return false
    }

    private func finish(loss: Bool) {
        stopLoop()
        phase = loss ? .lost : .won
    }
}
