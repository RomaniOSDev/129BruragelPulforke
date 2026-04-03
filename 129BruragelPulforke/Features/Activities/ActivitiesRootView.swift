//
//  ActivitiesRootView.swift
//  129BruragelPulforke
//

import SwiftUI

struct ActivitiesRootView: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose Your Challenge")
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Pick a route, dial the difficulty, then climb the grid.")
                        .foregroundStyle(Color.appTextSecondary)

                    ForEach(ActivityKind.allCases, id: \.self) { activity in
                        NavigationLink {
                            ActivityDetailView(activity: activity)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(activity.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    Text(activity.headline)
                                        .font(.footnote)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.appAccent)
                            }
                            .padding(16)
                            .frame(minHeight: GameConstants.minTapTarget)
                            .appDepthCard(cornerRadius: 16, elevated: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, GameConstants.horizontalPadding)
                .padding(.vertical, 20)
            }
            .appScreenBackdrop()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Operations")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
        }
    }
}
