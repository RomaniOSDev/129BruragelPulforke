//
//  SkyStrikeView.swift
//  129BruragelPulforke
//

import SwiftUI

struct SkyStrikeView: View {
    let difficulty: Difficulty
    @State private var stageLevel: Int

    init(level: Int, difficulty: Difficulty) {
        self.difficulty = difficulty
        _stageLevel = State(initialValue: level)
    }

    var body: some View {
        SkyStrikeRun(level: stageLevel, difficulty: difficulty, stageLevel: $stageLevel)
            .id("\(stageLevel)-\(difficulty.rawValue)-sky")
            .navigationTitle(ActivityKind.skyStrike.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SkyStrikeRun: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var stageLevel: Int

    @StateObject private var vm: SkyStrikeViewModel
    @EnvironmentObject private var store: GameProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var outcome: ActivityRunSummary?
    @State private var lockedOutcome = false

    init(level: Int, difficulty: Difficulty, stageLevel: Binding<Int>) {
        self.level = level
        self.difficulty = difficulty
        _stageLevel = stageLevel
        _vm = StateObject(wrappedValue: SkyStrikeViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Score \(vm.score)")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.headline.monospacedDigit())
                Spacer()
                Label("Lives \(vm.lives)", systemImage: "heart.fill")
                    .foregroundStyle(Color.appAccent)
                    .font(.headline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .appDepthCard(cornerRadius: 16, elevated: false)

            GeometryReader { geo in
                ZStack {
                    ForEach(vm.enemies) { e in
                        Path { p in
                            let r = e.size * min(geo.size.width, geo.size.height)
                            let c = CGPoint(x: e.center.x * geo.size.width, y: e.center.y * geo.size.height)
                            p.addEllipse(in: CGRect(x: c.x - r / 2, y: c.y - r / 2, width: r, height: r))
                        }
                        .fill(Color.appPrimary.opacity(0.9))
                    }

                    ForEach(vm.bolts) { b in
                        Capsule()
                            .fill(Color.appAccent)
                            .frame(width: 6, height: 14)
                            .position(x: b.center.x * geo.size.width, y: b.center.y * geo.size.height)
                    }

                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 28, height: 28)
                        .position(x: vm.playerX * geo.size.width, y: geo.size.height * 0.86)

                    if vm.phase == .ready {
                        readyOverlay
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            let nx = v.location.x / geo.size.width
                            vm.movePlayer(toNormalizedX: nx)
                        }
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        vm.fireBolt()
                    }
                )
            }
            .frame(height: 400)
            .appDepthInsetPanel(cornerRadius: 22)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("Drag to slide. Tap to launch bursts. Protect the lane.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, GameConstants.horizontalPadding)
        .padding(.vertical, 16)
        .appScreenBackdrop()
        .fullScreenCover(item: $outcome) { summary in
            ActivityResultView(
                summary: summary,
                accuracyPercent: skyAccuracy(),
                onRetry: {
                    outcome = nil
                    lockedOutcome = false
                    vm.resetSession()
                    vm.start()
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
            vm.resetSession()
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
                activity: .skyStrike,
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

    private func skyAccuracy() -> Int {
        let shots = max(1, vm.shotsFired)
        return min(100, Int((Double(vm.impacts) / Double(shots)) * 100))
    }

    private var readyOverlay: some View {
        VStack(spacing: 12) {
            Text("Stage \(level)")
                .font(.title3.bold())
                .foregroundStyle(Color.appTextPrimary)
            AppPrimaryButton(title: "Launch Sortie") {
                vm.start()
            }
            .padding(.horizontal, 20)
        }
        .padding(18)
        .appDepthCard(cornerRadius: 18, elevated: true)
    }
}
