//
//  SkyStrikeViewModel.swift
//  129BruragelPulforke
//

import Combine
import CoreGraphics
import Foundation
import SwiftUI

@MainActor
final class SkyStrikeViewModel: ObservableObject {
    enum Phase: Equatable {
        case ready
        case playing
        case won
        case lost
    }

    struct Enemy: Identifiable {
        let id = UUID()
        var center: CGPoint
        let size: CGFloat
        var speed: CGFloat
    }

    struct Bolt: Identifiable {
        let id = UUID()
        var center: CGPoint
    }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var playerX: CGFloat = 0.5
    @Published private(set) var score: Int = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var lives: Int
    @Published private(set) var enemies: [Enemy] = []
    @Published private(set) var bolts: [Bolt] = []
    @Published private(set) var shotsFired: Int = 0
    @Published private(set) var impacts: Int = 0

    private var ticker: AnyCancellable?
    private var spawnClock: TimeInterval = 0
    private var lastTick: Date?

    let level: Int
    let difficulty: Difficulty

    private let targetKillsBase: Int

    private var eliminated: Int = 0

    init(level: Int, difficulty: Difficulty) {
        self.level = level
        self.difficulty = difficulty
        lives = difficulty.lives
        targetKillsBase = 6 + level * 2
    }

    func resetSession() {
        stopLoop()
        phase = .ready
        elapsed = 0
        score = 0
        lives = difficulty.lives
        enemies = []
        bolts = []
        spawnClock = 0
        eliminated = 0
        shotsFired = 0
        impacts = 0
        playerX = 0.5
    }

    func start() {
        guard phase == .ready else { return }
        phase = .playing
        lastTick = Date()
        ticker?.cancel()
        ticker = Timer.publish(every: 1 / 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stopLoop() {
        ticker?.cancel()
        ticker = nil
    }

    func movePlayer(toNormalizedX x: CGFloat) {
        playerX = min(max(x, 0.08), 0.92)
    }

    func fireBolt() {
        guard phase == .playing else { return }
        shotsFired += 1
        var next = bolts
        next.append(Bolt(center: CGPoint(x: playerX, y: 0.82)))
        bolts = next
    }

    private func tick() {
        guard phase == .playing else { return }
        let now = Date()
        let dt = lastTick.map { now.timeIntervalSince($0) } ?? 0.016
        lastTick = now
        elapsed += dt
        spawnClock += dt

        let spawnEvery = max(0.45, 1.05 - 0.08 * Double(level)) / difficulty.enemyCountMultiplier
        if spawnClock > spawnEvery {
            spawnClock = 0
            spawnEnemy()
        }

        var nextBolts = bolts
        for i in nextBolts.indices {
            nextBolts[i].center.y -= CGFloat(dt * 0.85)
        }
        nextBolts.removeAll { $0.center.y < -0.05 }
        bolts = nextBolts

        var nextEnemies = enemies
        for i in nextEnemies.indices {
            nextEnemies[i].center.y += nextEnemies[i].speed * CGFloat(dt)
        }
        enemies = nextEnemies

        resolveCollisions()

        var trimmed = enemies
        trimmed.removeAll { enemy in
            if enemy.center.y > 0.94 {
                lives -= 1
                return true
            }
            return false
        }
        enemies = trimmed

        if lives <= 0 {
            finish(win: false)
            return
        }

        let goal = Int(Double(targetKillsBase) * difficulty.enemyCountMultiplier)
        if eliminated >= goal {
            score += 90
            finish(win: true)
        }
    }

    private func spawnEnemy() {
        let rx = CGFloat.random(in: 0.12 ... 0.88)
        let spd = CGFloat(0.35 + 0.04 * CGFloat(level)) * CGFloat(difficulty.obstacleSpeedMultiplier)
        let sz = CGFloat(0.065 + Double(level % 3) * 0.01)
        var next = enemies
        next.append(Enemy(center: CGPoint(x: rx, y: -0.05), size: sz, speed: spd))
        enemies = next
    }

    private func resolveCollisions() {
        var nextBolts = bolts
        var nextEnemies = enemies
        var i = 0
        while i < nextBolts.count {
            var hit = false
            for j in nextEnemies.indices {
                let b = nextBolts[i].center
                let e = nextEnemies[j].center
                let d = hypot(b.x - e.x, b.y - e.y)
                if d < nextEnemies[j].size {
                    nextEnemies.remove(at: j)
                    nextBolts.remove(at: i)
                    eliminated += 1
                    impacts += 1
                    score += 35
                    hit = true
                    break
                }
            }
            if !hit {
                i += 1
            }
        }
        bolts = nextBolts
        enemies = nextEnemies
    }

    private func finish(win: Bool) {
        stopLoop()
        phase = win ? .won : .lost
    }
}
