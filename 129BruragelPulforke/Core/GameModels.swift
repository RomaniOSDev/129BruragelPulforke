//
//  GameModels.swift
//  129BruragelPulforke
//

import CoreGraphics
import Foundation

enum GameConstants {
    static let levelCount = 6
    static let horizontalPadding: CGFloat = 16
    static let minTapTarget: CGFloat = 44
}

enum ActivityKind: String, CaseIterable, Codable, Hashable {
    case blitzDash
    case skyStrike
    case stealthSprint

    var title: String {
        switch self {
        case .blitzDash: return "Blitz Dash"
        case .skyStrike: return "Sky Strike"
        case .stealthSprint: return "Stealth Sprint"
        }
    }

    var headline: String {
        switch self {
        case .blitzDash: return "Swipe through hazards and reach the goal."
        case .skyStrike: return "Drag, tap to strike, and clear the skies."
        case .stealthSprint: return "Time every move between cover and slip past patrols."
        }
    }
}

enum Difficulty: String, CaseIterable, Codable, Hashable {
    case easy
    case normal
    case hard

    var title: String {
        rawValue.capitalized
    }

    var obstacleSpeedMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .normal: return 1.35
        case .hard: return 1.75
        }
    }

    var enemyCountMultiplier: Double {
        switch self {
        case .easy: return 0.75
        case .normal: return 1.0
        case .hard: return 1.35
        }
    }

    var lives: Int {
        switch self {
        case .easy: return 5
        case .normal: return 4
        case .hard: return 3
        }
    }

    /// Full patrol cycle length for Stealth Sprint (longer = slower, easier to read).
    var patrolThinkInterval: TimeInterval {
        switch self {
        case .easy: return 2.35
        case .normal: return 1.95
        case .hard: return 1.55
        }
    }
}

struct LevelThresholds: Hashable {
    let scoreForTwoStars: Int
    let timeForThreeStars: TimeInterval

    static func thresholds(level: Int, difficulty: Difficulty, activity: ActivityKind) -> LevelThresholds {
        let idx = max(1, min(GameConstants.levelCount, level))
        let baseScore: Int
        switch activity {
        case .blitzDash: baseScore = 80 + idx * 40
        case .skyStrike: baseScore = 120 + idx * 55
        case .stealthSprint: baseScore = 60 + idx * 35
        }
        let mult: Double
        let timeCap: TimeInterval
        switch difficulty {
        case .easy:
            mult = 0.9
            timeCap = 72 - Double(idx) * 4
        case .normal:
            mult = 1.0
            timeCap = 60 - Double(idx) * 3
        case .hard:
            mult = 1.15
            timeCap = 48 - Double(idx) * 2.5
        }
        let threeStarTime: TimeInterval
        if activity == .stealthSprint {
            switch difficulty {
            case .easy:
                threeStarTime = 110 - Double(idx) * 6
            case .normal:
                threeStarTime = 92 - Double(idx) * 5
            case .hard:
                threeStarTime = 78 - Double(idx) * 4
            }
        } else {
            threeStarTime = timeCap
        }
        return LevelThresholds(
            scoreForTwoStars: max(50, Int(Double(baseScore) * mult)),
            timeForThreeStars: max(22, threeStarTime)
        )
    }
}

enum StarCalculator {
    static func starsEarned(won: Bool, score: Int, duration: TimeInterval, thresholds: LevelThresholds) -> Int {
        guard won else { return 0 }
        let meetsScore = score >= thresholds.scoreForTwoStars
        let meetsTime = duration <= thresholds.timeForThreeStars
        if meetsScore, meetsTime { return 3 }
        if meetsScore { return 2 }
        return 1
    }
}

struct ActivityRunSummary: Hashable, Identifiable {
    var id: String {
        "\(activity.rawValue)-\(level)-\(difficulty.rawValue)-\(score)-\(Int(duration * 1000))"
    }

    let activity: ActivityKind
    let level: Int
    let difficulty: Difficulty
    let won: Bool
    let score: Int
    let duration: TimeInterval
    let starsEarned: Int
    let newlyUnlockedAchievementIds: [String]
}

enum AppTab: Hashable {
    case home
    case activities
    case leaderboard
    case profile
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id: String
    let activity: ActivityKind
    let level: Int
    let score: Int
}

extension Notification.Name {
    static let gameProgressReset = Notification.Name("gameProgressReset")
}
