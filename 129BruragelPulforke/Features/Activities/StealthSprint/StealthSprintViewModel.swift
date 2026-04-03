//
//  StealthSprintViewModel.swift
//  129BruragelPulforke
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class StealthSprintViewModel: ObservableObject {
    enum Phase: Equatable {
        case ready
        case playing
        case won
        case lost
    }

    enum WindowState: String {
        case calm
        case alert
    }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var coverIndex: Int = 0
    @Published private(set) var windowState: WindowState = .calm
    @Published private(set) var score: Int = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var cycleProgress: Double = 0
    @Published private(set) var attempts: Int = 0
    @Published private(set) var cleanMoves: Int = 0

    let level: Int
    let difficulty: Difficulty

    private var ticker: AnyCancellable?
    private var phaseElapsed: TimeInterval = 0
    private var patrolDuration: TimeInterval
    private var calmFraction: Double

    private var coverCount: Int {
        min(9, 4 + level)
    }

    init(level: Int, difficulty: Difficulty) {
        self.level = level
        self.difficulty = difficulty
        let base = difficulty.patrolThinkInterval
        patrolDuration = base * (1.0 + 0.06 * Double(min(level, 6)))
        switch difficulty {
        case .easy:
            calmFraction = 0.72
        case .normal:
            calmFraction = 0.64
        case .hard:
            calmFraction = 0.56
        }
    }

    func resetSession() {
        stopLoop()
        phase = .ready
        coverIndex = 0
        windowState = .calm
        score = 50
        elapsed = 0
        cycleProgress = 0
        phaseElapsed = 0
        attempts = 0
        cleanMoves = 0
    }

    func start() {
        guard phase == .ready else { return }
        phase = .playing
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

    func attemptAdvance() {
        guard phase == .playing else { return }
        attempts += 1
        if windowState == .calm {
            cleanMoves += 1
            if coverIndex >= coverCount - 1 {
                score += 140 + level * 15
                finish(win: true)
                return
            }
            coverIndex += 1
            score += 40
        } else {
            finish(win: false)
        }
    }

    private func tick() {
        guard phase == .playing else { return }
        let dt = 1.0 / 60.0
        elapsed += dt
        phaseElapsed += dt
        let cycle = patrolDuration
        let u = phaseElapsed.truncatingRemainder(dividingBy: cycle) / cycle
        cycleProgress = u
        let isCalm = u < calmFraction
        windowState = isCalm ? .calm : .alert

        if elapsed > 150 {
            finish(win: false)
        }
    }

    private func finish(win: Bool) {
        stopLoop()
        phase = win ? .won : .lost
    }
}
