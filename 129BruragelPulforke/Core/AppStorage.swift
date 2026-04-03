//
//  AppStorage.swift
//  129BruragelPulforke
//
//  Single source of truth for persisted progress (UserDefaults).

import Combine
import Foundation

@MainActor
final class GameProgressStore: ObservableObject {
    static let shared = GameProgressStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let onboarding = "hr.hasSeenOnboarding"
        static let playtimeSeconds = "hr.totalPlaySeconds"
        static let activitiesPlayed = "hr.activitiesPlayed"
        static let maxUnlockedPrefix = "hr.maxUnlocked."
        static let starsPrefix = "hr.stars."
        static let bestScorePrefix = "hr.bestScore."
        static let achievements = "hr.achievements.earned"
    }

    @Published private(set) var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.onboarding) }
    }

    @Published private(set) var totalPlaySeconds: TimeInterval {
        didSet { defaults.set(totalPlaySeconds, forKey: Keys.playtimeSeconds) }
    }

    @Published private(set) var totalActivitiesPlayed: Int {
        didSet { defaults.set(totalActivitiesPlayed, forKey: Keys.activitiesPlayed) }
    }

    @Published private(set) var earnedAchievementIds: Set<String> {
        didSet {
            defaults.set(Array(earnedAchievementIds), forKey: Keys.achievements)
        }
    }

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.onboarding)
        totalPlaySeconds = defaults.double(forKey: Keys.playtimeSeconds)
        totalActivitiesPlayed = defaults.integer(forKey: Keys.activitiesPlayed)
        let stored = defaults.stringArray(forKey: Keys.achievements) ?? []
        earnedAchievementIds = Set(stored)
    }

    func setOnboardingSeen() {
        hasSeenOnboarding = true
    }

    func stars(activity: ActivityKind, level: Int) -> Int {
        let key = Keys.starsPrefix + activity.rawValue + ".\(level)"
        return defaults.integer(forKey: key)
    }

    private func setStarsIfHigher(_ value: Int, activity: ActivityKind, level: Int) {
        let key = Keys.starsPrefix + activity.rawValue + ".\(level)"
        let current = defaults.integer(forKey: key)
        if value > current {
            defaults.set(value, forKey: key)
            objectWillChange.send()
        }
    }

    func bestScore(activity: ActivityKind, level: Int) -> Int {
        let key = Keys.bestScorePrefix + activity.rawValue + ".\(level)"
        return defaults.integer(forKey: key)
    }

    private func updateBestScore(_ score: Int, activity: ActivityKind, level: Int) {
        let key = Keys.bestScorePrefix + activity.rawValue + ".\(level)"
        let current = defaults.integer(forKey: key)
        if score > current {
            defaults.set(score, forKey: key)
        }
    }

    func maxUnlockedLevel(activity: ActivityKind) -> Int {
        let key = Keys.maxUnlockedPrefix + activity.rawValue
        let v = defaults.integer(forKey: key)
        if v == 0 {
            return 1
        }
        return min(GameConstants.levelCount, max(1, v))
    }

    private func bumpUnlockedIfNeeded(activity: ActivityKind, completedLevel: Int, won: Bool) {
        guard won else { return }
        let key = Keys.maxUnlockedPrefix + activity.rawValue
        let current = maxUnlockedLevel(activity: activity)
        let nextUnlock = min(GameConstants.levelCount, max(current, completedLevel + 1))
        defaults.set(nextUnlock, forKey: key)
    }

    func isLevelUnlocked(activity: ActivityKind, level: Int) -> Bool {
        level <= maxUnlockedLevel(activity: activity)
    }

    func totalStarsAcrossAllActivities() -> Int {
        var sum = 0
        for a in ActivityKind.allCases {
            for i in 1...GameConstants.levelCount {
                sum += stars(activity: a, level: i)
            }
        }
        return sum
    }

    func recordRun(summary: ActivityRunSummary) {
        totalPlaySeconds += summary.duration
        totalActivitiesPlayed += 1
        updateBestScore(summary.score, activity: summary.activity, level: summary.level)
        setStarsIfHigher(summary.starsEarned, activity: summary.activity, level: summary.level)
        bumpUnlockedIfNeeded(activity: summary.activity, completedLevel: summary.level, won: summary.won)
        var next = earnedAchievementIds
        for id in summary.newlyUnlockedAchievementIds {
            next.insert(id)
        }
        earnedAchievementIds = next
        objectWillChange.send()
    }

    private func totalStarsAcrossAllActivitiesWithPending(_ pending: ActivityRunSummary) -> Int {
        var sum = 0
        for a in ActivityKind.allCases {
            for i in 1...GameConstants.levelCount {
                var v = stars(activity: a, level: i)
                if a == pending.activity, i == pending.level {
                    v = max(v, pending.starsEarned)
                }
                sum += v
            }
        }
        return sum
    }

    private func allLevelsPerfect(activity: ActivityKind, pending: ActivityRunSummary) -> Bool {
        for i in 1...GameConstants.levelCount {
            var s = stars(activity: activity, level: i)
            if activity == pending.activity, i == pending.level {
                s = max(s, pending.starsEarned)
            }
            if s < 3 { return false }
        }
        return true
    }

    func buildFinalSummary(
        activity: ActivityKind,
        level: Int,
        difficulty: Difficulty,
        won: Bool,
        score: Int,
        duration: TimeInterval
    ) -> ActivityRunSummary {
        let thresholds = LevelThresholds.thresholds(level: level, difficulty: difficulty, activity: activity)
        let stars = StarCalculator.starsEarned(won: won, score: score, duration: duration, thresholds: thresholds)
        let previous = earnedAchievementIds
        let pending = ActivityRunSummary(
            activity: activity,
            level: level,
            difficulty: difficulty,
            won: won,
            score: score,
            duration: duration,
            starsEarned: stars,
            newlyUnlockedAchievementIds: []
        )
        let hypotheticalPlayed = totalActivitiesPlayed + (won || score > 0 ? 1 : 0)
        let hypotheticalTime = totalPlaySeconds + duration
        var hypotheticalStars = totalStarsAcrossAllActivitiesWithPending(pending)

        var newIds: [String] = []
        func consider(_ id: String, _ condition: Bool) {
            guard condition, !previous.contains(id), !newIds.contains(id) else { return }
            newIds.append(id)
        }

        consider(AchievementId.firstVictory, won)
        consider(AchievementId.tripleExcellence, stars >= 3)
        consider(AchievementId.hourInAction, hypotheticalTime >= 3600)
        consider(AchievementId.fiftyRuns, hypotheticalPlayed >= 50)
        consider(AchievementId.starHunter, hypotheticalStars >= 40)

        for a in ActivityKind.allCases where allLevelsPerfect(activity: a, pending: pending) {
            switch a {
            case .blitzDash: consider(AchievementId.blitzLegend, true)
            case .skyStrike: consider(AchievementId.skyLegend, true)
            case .stealthSprint: consider(AchievementId.shadowLegend, true)
            }
        }

        return ActivityRunSummary(
            activity: activity,
            level: level,
            difficulty: difficulty,
            won: won,
            score: score,
            duration: duration,
            starsEarned: stars,
            newlyUnlockedAchievementIds: newIds
        )
    }

    func leaderboardTopScores(limitPerActivity: Int = 12) -> [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = []
        for a in ActivityKind.allCases {
            for lv in 1...GameConstants.levelCount {
                let s = bestScore(activity: a, level: lv)
                if s > 0 {
                    let id = "\(a.rawValue)-\(lv)-\(s)"
                    entries.append(LeaderboardEntry(id: id, activity: a, level: lv, score: s))
                }
            }
        }
        var result: [LeaderboardEntry] = []
        for a in ActivityKind.allCases {
            let slice = entries.filter { $0.activity == a }
                .sorted { $0.score > $1.score }
                .prefix(limitPerActivity)
            result.append(contentsOf: slice)
        }
        return result.sorted { $0.score > $1.score }
    }

    func resetAllProgress() {
        let dict = defaults.dictionaryRepresentation()
        for key in dict.keys where key.hasPrefix("hr.") {
            defaults.removeObject(forKey: key)
        }
        hasSeenOnboarding = false
        totalPlaySeconds = 0
        totalActivitiesPlayed = 0
        earnedAchievementIds = []
        for a in ActivityKind.allCases {
            defaults.set(1, forKey: Keys.maxUnlockedPrefix + a.rawValue)
        }
        objectWillChange.send()
        NotificationCenter.default.post(name: .gameProgressReset, object: nil)
    }

    func achievementTitle(for id: String) -> String {
        switch id {
        case AchievementId.firstVictory: return "First Breakthrough"
        case AchievementId.tripleExcellence: return "Triple Excellence"
        case AchievementId.hourInAction: return "Hour in the Zone"
        case AchievementId.fiftyRuns: return "Fifty Sorties"
        case AchievementId.starHunter: return "Constellation"
        case AchievementId.blitzLegend: return "Blitz Legend"
        case AchievementId.skyLegend: return "Sky Legend"
        case AchievementId.shadowLegend: return "Shadow Legend"
        default: return "Achievement"
        }
    }

    func achievementBlurb(for id: String) -> String {
        switch id {
        case AchievementId.firstVictory: return "Clear any stage successfully."
        case AchievementId.tripleExcellence: return "Earn three stars on a stage."
        case AchievementId.hourInAction: return "Accumulate 60 minutes of active play."
        case AchievementId.fiftyRuns: return "Complete or attempt 50 activities."
        case AchievementId.starHunter: return "Collect 40 stars across all stages."
        case AchievementId.blitzLegend: return "Three stars on every Blitz Dash stage."
        case AchievementId.skyLegend: return "Three stars on every Sky Strike stage."
        case AchievementId.shadowLegend: return "Three stars on every Stealth Sprint stage."
        default: return ""
        }
    }

    var achievementsDisplayList: [(id: String, unlocked: Bool)] {
        AchievementId.all.map { id in
            (id, earnedAchievementIds.contains(id))
        }
    }
}

enum AchievementId {
    static let firstVictory = "ach.firstVictory"
    static let tripleExcellence = "ach.tripleExcellence"
    static let hourInAction = "ach.hourInAction"
    static let fiftyRuns = "ach.fiftyRuns"
    static let starHunter = "ach.starHunter"
    static let blitzLegend = "ach.blitzLegend"
    static let skyLegend = "ach.skyLegend"
    static let shadowLegend = "ach.shadowLegend"

    static let all: [String] = [
        firstVictory,
        tripleExcellence,
        hourInAction,
        fiftyRuns,
        starHunter,
        blitzLegend,
        skyLegend,
        shadowLegend,
    ]
}
