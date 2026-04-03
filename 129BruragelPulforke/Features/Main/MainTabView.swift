//
//  MainTabView.swift
//  129BruragelPulforke
//

import SwiftUI

struct MainTabView: View {
    @State private var tab: AppTab = .home

    var body: some View {
        TabView(selection: $tab) {
            HomeView(selectedTab: $tab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            ActivitiesRootView()
                .tabItem {
                    Label("Activities", systemImage: "bolt.circle.fill")
                }
                .tag(AppTab.activities)

            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.leaderboard)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(Color.appPrimary)
        .appTabBarChrome()
        .onReceive(NotificationCenter.default.publisher(for: .gameProgressReset)) { _ in
            tab = .home
        }
    }
}
