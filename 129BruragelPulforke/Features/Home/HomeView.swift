//
//  HomeView.swift
//  129BruragelPulforke
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var store: GameProgressStore

    @State private var appeared = false
    @State private var pulseBreathe = false

    private var totalStars: Int {
        ActivityKind.allCases.reduce(0) { acc, a in
            acc + (1...GameConstants.levelCount).reduce(0) { $0 + store.stars(activity: a, level: $1) }
        }
    }

    private var maxStars: Int {
        ActivityKind.allCases.count * GameConstants.levelCount * 3
    }

    private var progress: Double {
        guard maxStars > 0 else { return 0 }
        return min(1, Double(totalStars) / Double(maxStars))
    }

    private var focusActivity: ActivityKind? {
        ActivityKind.allCases.min(by: { starsSum($0) < starsSum($1) })
    }

    private var unlockedAchievementCount: Int {
        store.earnedAchievementIds.count
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroSection
                    statsRow
                    starProgressCard
                    quickDestinations
                    activitiesSection
                    focusCard
                }
                .padding(.horizontal, GameConstants.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .appScreenBackdrop()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Command Deck")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    pulseBreathe = true
                }
            }
        }
    }

    private func starsSum(_ activity: ActivityKind) -> Int {
        (1...GameConstants.levelCount).reduce(0) { $0 + store.stars(activity: activity, level: $1) }
    }

    private func homeMiniStarFill(_ sum: Int) -> Int {
        if sum <= 0 { return 0 }
        let r = sum % 3
        return r == 0 ? 3 : r
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let w = size.width
                    let h = size.height
                    var base = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 22)
                    ctx.fill(base, with: .linearGradient(
                        Gradient(colors: [Color.appSurface, Color.appSurface.opacity(0.92)]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: w, y: h)
                    ))
                    for i in 0..<5 {
                        let phase = t * 0.9 + Double(i) * 0.7
                        var arc = Path()
                        let cx = w * (0.2 + 0.15 * CGFloat(i))
                        let cy = h * 0.45
                        let r = 28 + CGFloat(i) * 5 + CGFloat(sin(phase)) * 4
                        arc.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
                        ctx.stroke(arc, with: .color(Color.appAccent.opacity(0.22 + 0.08 * Double(i % 2))), lineWidth: 2)
                    }
                    var bolt = Path()
                    bolt.move(to: CGPoint(x: w * 0.72, y: h * 0.22))
                    bolt.addLine(to: CGPoint(x: w * 0.82, y: h * 0.38))
                    bolt.addLine(to: CGPoint(x: w * 0.76, y: h * 0.38))
                    bolt.addLine(to: CGPoint(x: w * 0.88, y: h * 0.72))
                    bolt.addLine(to: CGPoint(x: w * 0.62, y: h * 0.42))
                    bolt.addLine(to: CGPoint(x: w * 0.7, y: h * 0.42))
                    bolt.closeSubpath()
                    ctx.fill(bolt, with: .color(Color.appPrimary.opacity(0.35)))
                }
            }
            .frame(height: 148)
            .scaleEffect(appeared ? 1 : 0.94, anchor: .center)
            .opacity(appeared ? 1 : 0.75)
            .animation(.spring(response: 0.55, dampingFraction: 0.82), value: appeared)

            VStack(alignment: .leading, spacing: 6) {
                Text("Ready when you are")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Text("Push reflexes, rhythm, and timing in three forged challenges.")
                    .font(.title3.bold())
                    .foregroundStyle(Color.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Swipe, strike, and slip through patrol windows — stars reward clean clears.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .appDepthCard(cornerRadius: 24, elevated: true)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.appPrimary.opacity(pulseBreathe ? 0.22 : 0.12), lineWidth: 1)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(
                title: "Stars",
                value: "\(totalStars)",
                caption: "of \(maxStars)",
                icon: "star.fill",
                action: { selectedTab = .activities }
            )
            statTile(
                title: "Runs",
                value: "\(store.totalActivitiesPlayed)",
                caption: "logged",
                icon: "flame.fill",
                action: { selectedTab = .profile }
            )
            statTile(
                title: "Badges",
                value: "\(unlockedAchievementCount)",
                caption: "unlocked",
                icon: "seal.fill",
                action: { selectedTab = .profile }
            )
        }
    }

    private func statTile(title: String, value: String, caption: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                    Spacer(minLength: 0)
                }
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .appDepthCard(cornerRadius: 16, elevated: false)
        }
        .buttonStyle(.plain)
        .frame(minHeight: GameConstants.minTapTarget)
    }

    private var starProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Constellation progress")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.appAccent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSurface)
                        .overlay(Capsule().stroke(Color.appTextSecondary.opacity(0.12), lineWidth: 1))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, geo.size.width * progress))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 14)

            HStack(spacing: 6) {
                ForEach(0..<progressSegmentCount, id: \.self) { i in
                    Circle()
                        .fill(segmentFilled(index: i) ? Color.appAccent : Color.appTextSecondary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .appDepthCard(cornerRadius: 20, elevated: true)
    }

    private var progressSegmentCount: Int {
        max(1, min(12, maxStars / 5))
    }

    private func segmentFilled(index: Int) -> Bool {
        let segments = progressSegmentCount
        guard maxStars > 0 else { return false }
        let threshold = Double(totalStars) / Double(maxStars) * Double(segments)
        return Double(index) < threshold
    }

    private var quickDestinations: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shortcuts")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            HStack(spacing: 10) {
                shortcutChip(title: "Activities", systemImage: "bolt.fill") {
                    selectedTab = .activities
                }
                shortcutChip(title: "Leaderboard", systemImage: "chart.bar.fill") {
                    selectedTab = .leaderboard
                }
                shortcutChip(title: "Profile", systemImage: "person.fill") {
                    selectedTab = .profile
                }
            }
        }
    }

    private func shortcutChip(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(Color.appTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .appDepthCard(cornerRadius: 14, elevated: false)
        }
        .buttonStyle(.plain)
        .frame(minHeight: GameConstants.minTapTarget)
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Operations roster")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Button {
                    selectedTab = .activities
                } label: {
                    Text("See all")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(.plain)
                .frame(minWidth: GameConstants.minTapTarget, minHeight: GameConstants.minTapTarget)
            }

            ForEach(ActivityKind.allCases, id: \.self) { activity in
                activityCard(activity: activity, highlight: focusActivity == activity)
            }
        }
    }

    private func activityCard(activity: ActivityKind, highlight: Bool) -> some View {
        let sum = starsSum(activity)
        let cap = GameConstants.levelCount * 3
        let unlocked = store.maxUnlockedLevel(activity: activity)

        return Button {
            selectedTab = .activities
        } label: {
            HStack(spacing: 14) {
                ActivityGlyph(activity: activity, prominent: highlight)
                    .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(activity.title)
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 8)
                        StarsRowView(filled: homeMiniStarFill(sum), maxStars: 3, glow: sum >= cap)
                    }

                    Text(activity.headline)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    HStack(spacing: 10) {
                        Label("\(sum)/\(cap) stars", systemImage: "star.leadinghalf.filled")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("·")
                            .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                        Text("Unlocked through \(unlocked)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                }
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(16)
            .appDepthCard(cornerRadius: 20, elevated: highlight)
            .overlay {
                if highlight {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.65), Color.appPrimary.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: GameConstants.minTapTarget)
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sharpen the edge")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            if let focus = focusActivity {
                let sum = starsSum(focus)
                Text("Right now \(focus.title) has the lightest star load (\(sum) collected). A focused run there tightens your mastery curve.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                AppPrimaryButton(title: "Jump to \(focus.title)") {
                    selectedTab = .activities
                }
            } else {
                Text("Open the roster and pick any lane — every clear chips away at the next unlock.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                AppPrimaryButton(title: "Browse Activities") {
                    selectedTab = .activities
                }
            }
        }
        .padding(20)
        .appDepthCard(cornerRadius: 22, elevated: true)
    }
}

private struct ActivityGlyph: View {
    let activity: ActivityKind
    var prominent: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(prominent ? 0.35 : 0.2),
                            Color.appAccent.opacity(0.12),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Group {
                switch activity {
                case .blitzDash:
                    Path { p in
                        p.move(to: CGPoint(x: 12, y: 38))
                        p.addLine(to: CGPoint(x: 38, y: 14))
                        p.addLine(to: CGPoint(x: 46, y: 42))
                    }
                    .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                case .skyStrike:
                    Circle()
                        .stroke(Color.appAccent, lineWidth: 3)
                        .frame(width: 30, height: 30)
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 9, height: 9)
                        .offset(x: 10, y: -10)
                case .stealthSprint:
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appAccent.opacity(0.88))
                        .frame(width: 34, height: 9)
                        .offset(y: 12)
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 13, height: 13)
                        .offset(y: -9)
                }
            }
            .frame(width: 56, height: 56)
        }
    }
}
