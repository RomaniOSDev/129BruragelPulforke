//
//  BlitzDashView.swift
//  129BruragelPulforke
//

import SwiftUI

struct BlitzDashView: View {
    let difficulty: Difficulty
    @State private var stageLevel: Int

    init(level: Int, difficulty: Difficulty) {
        self.difficulty = difficulty
        _stageLevel = State(initialValue: level)
    }

    var body: some View {
        BlitzDashRun(level: stageLevel, difficulty: difficulty, stageLevel: $stageLevel)
            .id("\(stageLevel)-\(difficulty.rawValue)-blitz")
            .navigationTitle(ActivityKind.blitzDash.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BlitzDashRun: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var stageLevel: Int

    @StateObject private var vm: BlitzDashViewModel
    @EnvironmentObject private var store: GameProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var outcome: ActivityRunSummary?
    @State private var lockedOutcome = false

    init(level: Int, difficulty: Difficulty, stageLevel: Binding<Int>) {
        self.level = level
        self.difficulty = difficulty
        _stageLevel = stageLevel
        _vm = StateObject(wrappedValue: BlitzDashViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 16) {
            statsHeader

            GeometryReader { geo in
                ZStack {
                    goalLayer(size: geo.size)
                    hazardsLayer(size: geo.size)
                    orbsLayer(size: geo.size)
                    playerLayer(size: geo.size)

                    if vm.phase == .ready {
                        readyOverlay
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onEnded { value in
                            vm.handleSwipe(translation: value.translation)
                        }
                )
            }
            .frame(height: 360)
            .appDepthInsetPanel(cornerRadius: 22)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("Swipe to steer. Reach the safe zone. Grab charge orbs for score.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, GameConstants.horizontalPadding)
        }
        .padding(.horizontal, GameConstants.horizontalPadding)
        .padding(.vertical, 16)
        .appScreenBackdrop()
        .fullScreenCover(item: $outcome) { summary in
            ActivityResultView(
                summary: summary,
                accuracyPercent: blitzAccuracy(),
                onRetry: {
                    outcome = nil
                    lockedOutcome = false
                    vm.prepareArena()
                    vm.startRun()
                },
                onNextLevel: {
                    outcome = nil
                    lockedOutcome = false
                    stageLevel = min(GameConstants.levelCount, stageLevel + 1)
                },
                onBackToLevels: {
                    outcome = nil
                    dismiss()
                }
            )
            .environmentObject(store)
        }
        .onAppear {
            vm.prepareArena()
        }
        .onDisappear {
            vm.stopLoop()
        }
        .onChange(of: vm.phase) { newPhase in
            guard newPhase == .won || newPhase == .lost else { return }
            guard !lockedOutcome else { return }
            lockedOutcome = true
            let won = newPhase == .won
            let summary = store.buildFinalSummary(
                activity: .blitzDash,
                level: level,
                difficulty: difficulty,
                won: won,
                score: vm.score,
                duration: vm.elapsed
            )
            store.recordRun(summary: summary)
            outcome = summary
        }
    }

    private var statsHeader: some View {
        HStack {
            Text("Score \(vm.score)")
                .foregroundStyle(Color.appTextPrimary)
                .font(.headline.monospacedDigit())
            Spacer()
            Text(timerString(vm.elapsed))
                .foregroundStyle(Color.appAccent)
                .font(.headline.monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .appDepthCard(cornerRadius: 16, elevated: false)
    }

    private func blitzAccuracy() -> Int {
        let total = max(1, vm.orbs.count)
        return min(100, Int((Double(vm.orbsCollected) / Double(total)) * 100))
    }

    private func timerString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func goalLayer(size: CGSize) -> some View {
        let g = CGRect(x: 0.72 * size.width, y: 0.06 * size.height, width: 0.2 * size.width, height: 0.14 * size.height)
        return RoundedRectangle(cornerRadius: 10)
            .stroke(Color.appAccent, lineWidth: 2)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appAccent.opacity(0.12)))
            .frame(width: g.width, height: g.height)
            .position(x: g.midX, y: g.midY)
    }

    private func hazardsLayer(size: CGSize) -> some View {
        ForEach(vm.hazards) { h in
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.appPrimary.opacity(0.85))
                .frame(width: h.size.width * size.width, height: h.size.height * size.height)
                .position(x: h.center.x * size.width, y: h.center.y * size.height)
        }
    }

    private func orbsLayer(size: CGSize) -> some View {
        ForEach(vm.orbs) { o in
            if !o.collected {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 16, height: 16)
                    .position(x: o.center.x * size.width, y: o.center.y * size.height)
            }
        }
    }

    private func playerLayer(size: CGSize) -> some View {
        Circle()
            .fill(Color.appPrimary)
            .frame(width: 28, height: 28)
            .position(x: vm.player.x * size.width, y: vm.player.y * size.height)
    }

    private var readyOverlay: some View {
        VStack(spacing: 12) {
            Text("Stage \(level)")
                .font(.title3.bold())
                .foregroundStyle(Color.appTextPrimary)
            AppPrimaryButton(title: "Begin Run") {
                vm.startRun()
            }
            .padding(.horizontal, 20)
        }
        .padding(18)
        .appDepthCard(cornerRadius: 18, elevated: true)
    }
}
