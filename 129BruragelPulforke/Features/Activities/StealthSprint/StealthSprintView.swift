//
//  StealthSprintView.swift
//  129BruragelPulforke
//

import SwiftUI

struct StealthSprintView: View {
    let difficulty: Difficulty
    @State private var stageLevel: Int

    init(level: Int, difficulty: Difficulty) {
        self.difficulty = difficulty
        _stageLevel = State(initialValue: level)
    }

    var body: some View {
        StealthRun(level: stageLevel, difficulty: difficulty, stageLevel: $stageLevel)
            .id("\(stageLevel)-\(difficulty.rawValue)-stealth")
            .navigationTitle(ActivityKind.stealthSprint.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StealthRun: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var stageLevel: Int

    @StateObject private var vm: StealthSprintViewModel
    @EnvironmentObject private var store: GameProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var outcome: ActivityRunSummary?
    @State private var lockedOutcome = false

    init(level: Int, difficulty: Difficulty, stageLevel: Binding<Int>) {
        self.level = level
        self.difficulty = difficulty
        _stageLevel = stageLevel
        _vm = StateObject(wrappedValue: StealthSprintViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score \(vm.score)")
                        .foregroundStyle(Color.appTextPrimary)
                        .font(.headline.monospacedDigit())
                    Text(statusLine)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(vm.windowState == .calm ? Color.appAccent : Color.appPrimary)
                }
                Spacer()
                Text(timerString(vm.elapsed))
                    .foregroundStyle(Color.appTextSecondary)
                    .font(.headline.monospacedDigit())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .appDepthCard(cornerRadius: 16, elevated: false)

            GeometryReader { geo in
                ZStack {
                    coverPath(in: geo.size)
                        .stroke(Color.appTextSecondary.opacity(0.35), lineWidth: 2)

                    ForEach(0..<coverCount, id: \.self) { i in
                        let pt = coverPoint(index: i, in: geo.size)
                        Group {
                            if i == vm.coverIndex {
                                Circle()
                                    .fill(Color.appPrimary)
                                    .frame(width: 26, height: 26)
                            } else {
                                Circle()
                                    .stroke(Color.appAccent.opacity(0.7), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .position(pt)
                    }

                    patrolScanner(in: geo.size)

                    if vm.phase == .ready {
                        readyOverlay
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if vm.phase == .playing {
                        vm.attemptAdvance()
                    }
                }
            }
            .frame(height: 380)
            .appDepthInsetPanel(cornerRadius: 22)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            ProgressView(value: vm.cycleProgress)
                .tint(Color.appAccent)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
                .appDepthCard(cornerRadius: 12, elevated: false)

            Text("Tap during the calm pulse to leap to the next cover. Hold still when the pulse spikes.")
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
                accuracyPercent: stealthAccuracy(),
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
                activity: .stealthSprint,
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

    private var coverCount: Int {
        min(9, 4 + level)
    }

    private var statusLine: String {
        switch vm.windowState {
        case .calm: return "Calm window — advance"
        case .alert: return "Spike — hold position"
        }
    }

    private func coverPoint(index: Int, in size: CGSize) -> CGPoint {
        let t = CGFloat(index) / CGFloat(max(1, coverCount - 1))
        let x = 0.12 * size.width + t * 0.76 * size.width
        let wave = sin(t * .pi) * 0.12 * size.height
        let y = size.height * 0.55 + wave
        return CGPoint(x: x, y: y)
    }

    private func coverPath(in size: CGSize) -> Path {
        var p = Path()
        for i in 0..<coverCount {
            let pt = coverPoint(index: i, in: size)
            if i == 0 {
                p.move(to: pt)
            } else {
                p.addLine(to: pt)
            }
        }
        return p
    }

    private func patrolScanner(in size: CGSize) -> some View {
        let w = size.width * 0.7
        let x = size.width * 0.15 + CGFloat(vm.cycleProgress) * w
        return Path { p in
            p.move(to: CGPoint(x: x, y: size.height * 0.18))
            p.addLine(to: CGPoint(x: x, y: size.height * 0.32))
        }
        .stroke(Color.appPrimary.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 8]))
    }

    private func stealthAccuracy() -> Int {
        let taps = max(1, vm.attempts)
        return min(100, Int((Double(vm.cleanMoves) / Double(taps)) * 100))
    }

    private func timerString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private var readyOverlay: some View {
        VStack(spacing: 12) {
            Text("Stage \(level)")
                .font(.title3.bold())
                .foregroundStyle(Color.appTextPrimary)
            AppPrimaryButton(title: "Start Infiltration") {
                vm.start()
            }
            .padding(.horizontal, 20)
        }
        .padding(18)
        .appDepthCard(cornerRadius: 18, elevated: true)
    }
}
