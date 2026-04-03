//
//  ActivityResultView.swift
//  129BruragelPulforke
//

import SwiftUI

struct ActivityResultView: View {
    let summary: ActivityRunSummary
    var accuracyPercent: Int = 100
    @EnvironmentObject private var store: GameProgressStore

    var onRetry: () -> Void
    var onNextLevel: () -> Void
    var onBackToLevels: () -> Void

    @State private var starsVisible = 0
    @State private var bannerOffset: CGFloat = -220
    @State private var bannerOpacity: Double = 0

    private var canNext: Bool {
        summary.won && summary.level < GameConstants.levelCount
            && store.isLevelUnlocked(activity: summary.activity, level: summary.level + 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if summary.won {
                    Text("Stage Cleared")
                        .font(.title.bold())
                        .foregroundStyle(Color.appTextPrimary)
                } else {
                    Text("Mission Failed")
                        .font(.title.bold())
                        .foregroundStyle(Color.appTextPrimary)
                }

                VStack(spacing: 16) {
                    Text("Rewards")
                        .font(.headline)
                        .foregroundStyle(Color.appTextSecondary)

                    HStack(spacing: 18) {
                        ForEach(0..<3, id: \.self) { i in
                            starBubble(lit: i < summary.starsEarned, show: i < starsVisible)
                        }
                    }
                    .padding(.vertical, 6)

                    statRow(title: "Score", value: "\(summary.score)")
                    statRow(title: "Time", value: formattedTime(summary.duration))
                    statRow(title: "Accuracy", value: "\(accuracyPercent)%")
                }
                .padding(22)
                .appDepthCard(cornerRadius: 24, elevated: true)
                .padding(.horizontal, GameConstants.horizontalPadding)

                VStack(spacing: 12) {
                    if canNext {
                        AppPrimaryButton(title: "Next Level") {
                            onNextLevel()
                        }
                    }
                    AppSecondaryButton(title: "Retry") {
                        onRetry()
                    }
                    Button(action: onBackToLevels) {
                        Text("Back to Levels")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: GameConstants.minTapTarget)
                            .appDepthSecondaryCapsule(cornerRadius: 14)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, GameConstants.horizontalPadding)
            }
            .padding(.vertical, 24)
        }
        .appScreenBackdrop()
        .overlay(alignment: .top) {
            if let first = summary.newlyUnlockedAchievementIds.first {
                achievementBanner(title: store.achievementTitle(for: first), subtitle: store.achievementBlurb(for: first))
                    .offset(y: bannerOffset)
                    .opacity(bannerOpacity)
                    .padding(.top, 12)
                    .padding(.horizontal, GameConstants.horizontalPadding)
            }
        }
        .onAppear {
            animateStars()
            showBannerIfNeeded()
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    private func starBubble(lit: Bool, show: Bool) -> some View {
        ZStack {
            if lit && show {
                Circle()
                    .fill(Color.appAccent.opacity(0.35))
                    .frame(width: 70, height: 70)
                    .blur(radius: 10)
            }
            Image(systemName: lit && show ? "star.fill" : "star")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(lit && show ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                .scaleEffect(1)
        }
        .opacity(show ? 1 : 0.25)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: show)
    }

    private func achievementBanner(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Achievement Unlocked")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appDepthCard(cornerRadius: 18, elevated: true)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
    }

    private func formattedTime(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }

    private func animateStars() {
        starsVisible = 0
        let total = summary.starsEarned
        for i in 0..<total {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 * Double(i)) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) {
                    starsVisible = i + 1
                }
            }
        }
    }

    private func showBannerIfNeeded() {
        guard !summary.newlyUnlockedAchievementIds.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            bannerOffset = 0
            bannerOpacity = 1
        }
    }
}
