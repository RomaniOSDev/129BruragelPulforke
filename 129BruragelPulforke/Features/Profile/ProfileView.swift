//
//  ProfileView.swift
//  129BruragelPulforke
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var showResetConfirm = false
    @State private var refreshTick = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Statistics")
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    statGrid

                    Text("Achievements")
                        .font(.title3.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    VStack(spacing: 12) {
                        ForEach(store.achievementsDisplayList, id: \.id) { row in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: row.unlocked ? "seal.fill" : "seal")
                                    .foregroundStyle(row.unlocked ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.achievementTitle(for: row.id))
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                    Text(store.achievementBlurb(for: row.id))
                                        .font(.footnote)
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .appDepthCard(cornerRadius: 14, elevated: false)
                        }
                    }

                    AppPrimaryButton(title: "Reset All Progress", style: .surface) {
                        showResetConfirm = true
                    }

                    Text("Reset clears stars, unlocks, timers, scores, achievements, and shows onboarding again.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.horizontal, GameConstants.horizontalPadding)
                .padding(.vertical, 20)
            }
            .id(refreshTick)
            .appScreenBackdrop()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .alert("Reset Everything?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAllProgress()
                    refreshTick = UUID()
                }
            } message: {
                Text("This cannot be undone.")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gameProgressReset)) { _ in
                refreshTick = UUID()
            }
        }
    }

    private var statGrid: some View {
        let hours = Int(store.totalPlaySeconds) / 3600
        let minutes = (Int(store.totalPlaySeconds) % 3600) / 60
        let stars = ActivityKind.allCases.reduce(0) { partial, a in
            partial + (1...GameConstants.levelCount).reduce(0) { $0 + store.stars(activity: a, level: $1) }
        }

        return VStack(spacing: 12) {
            statCard(title: "Time in Action", value: String(format: "%dh %02dm", hours, minutes))
            statCard(title: "Runs Logged", value: "\(store.totalActivitiesPlayed)")
            statCard(title: "Stars Secured", value: "\(stars)")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .appDepthCard(cornerRadius: 16, elevated: false)
    }
}
