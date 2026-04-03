//
//  ActivityDetailView.swift
//  129BruragelPulforke
//

import SwiftUI

struct ActivityDetailView: View {
    let activity: ActivityKind
    @EnvironmentObject private var store: GameProgressStore
    @State private var difficulty: Difficulty = .normal

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(activity.headline)
                    .foregroundStyle(Color.appTextSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Difficulty")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)

                    HStack(spacing: 10) {
                        ForEach(Difficulty.allCases, id: \.self) { d in
                            Button {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    difficulty = d
                                }
                            } label: {
                                Text(d.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(difficulty == d ? Color.appTextPrimary : Color.appTextSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .frame(minHeight: GameConstants.minTapTarget)
                                    .appDepthDifficultyPill(selected: difficulty == d)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Levels")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(1...GameConstants.levelCount, id: \.self) { level in
                            let unlocked = store.isLevelUnlocked(activity: activity, level: level)
                            NavigationLink {
                                destination(for: level)
                            } label: {
                                LevelCell(
                                    level: level,
                                    stars: store.stars(activity: activity, level: level),
                                    locked: !unlocked
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!unlocked)
                        }
                    }
                }
            }
            .padding(.horizontal, GameConstants.horizontalPadding)
            .padding(.vertical, 20)
        }
        .appScreenBackdrop()
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func destination(for level: Int) -> some View {
        switch activity {
        case .blitzDash:
            BlitzDashView(level: level, difficulty: difficulty)
        case .skyStrike:
            SkyStrikeView(level: level, difficulty: difficulty)
        case .stealthSprint:
            StealthSprintView(level: level, difficulty: difficulty)
        }
    }
}

private struct LevelCell: View {
    let level: Int
    let stars: Int
    let locked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface,
                                Color.appBackground.opacity(0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                if locked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.appTextSecondary)
                } else {
                    Text("\(level)")
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
            .frame(height: 72)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appAccent.opacity(locked ? 0.08 : 0.22), lineWidth: 1)
            )

            StarsRowView(filled: stars, maxStars: 3)
                .opacity(locked ? 0.35 : 1)
        }
        .padding(12)
        .appDepthCard(cornerRadius: 18, elevated: !locked)
    }
}
