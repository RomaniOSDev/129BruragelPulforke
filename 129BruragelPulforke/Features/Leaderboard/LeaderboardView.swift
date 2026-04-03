//
//  LeaderboardView.swift
//  129BruragelPulforke
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var refreshTick = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Local Best Marks")
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Every peak score you set on a stage shows up here. Clear all progress in Profile to reset.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)

                    let entries = store.leaderboardTopScores(limitPerActivity: 12)

                    if entries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No records yet")
                                .font(.headline)
                                .foregroundStyle(Color.appTextPrimary)
                            Text("Finish any stage with a positive score to populate this board.")
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appDepthCard(cornerRadius: 16, elevated: true)
                    } else {
                        ForEach(ActivityKind.allCases, id: \.self) { activity in
                            let rows = entries.filter { $0.activity == activity }
                            if !rows.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(activity.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                    ForEach(rows) { row in
                                        HStack {
                                            Text("Stage \(row.level)")
                                                .foregroundStyle(Color.appTextSecondary)
                                            Spacer()
                                            Text("\(row.score)")
                                                .font(.headline.monospacedDigit())
                                                .foregroundStyle(Color.appAccent)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                }
                                .padding(16)
                                .appDepthCard(cornerRadius: 16, elevated: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, GameConstants.horizontalPadding)
                .padding(.vertical, 20)
            }
            .id(refreshTick)
            .appScreenBackdrop()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Leaderboard")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .gameProgressReset)) { _ in
                refreshTick = UUID()
            }
        }
    }
}
