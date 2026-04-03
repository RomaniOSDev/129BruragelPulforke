//
//  ContentView.swift
//  129BruragelPulforke
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = GameProgressStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .appScreenBackdrop()
    }
}

#Preview {
    ContentView()
}
