//
//  SettingsView.swift
//  129BruragelPulforke
//

import StoreKit
import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                settingsButton(
                    title: "Rate Us",
                    subtitle: "Share feedback in the App Store",
                    systemImage: "star.circle.fill"
                ) {
                    rateApp()
                }

                settingsButton(
                    title: "Privacy Policy",
                    subtitle: "How we handle your data",
                    systemImage: "hand.raised.fill"
                ) {
                    openPolicy(AppExternalLink.privacyPolicy)
                }

                settingsButton(
                    title: "Terms of Use",
                    subtitle: "Rules and conditions",
                    systemImage: "doc.text.fill"
                ) {
                    openPolicy(AppExternalLink.termsOfUse)
                }
            }
            .padding(.horizontal, GameConstants.horizontalPadding)
            .padding(.vertical, 20)
        }
        .appScreenBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
            }
        }
    }

    private func openPolicy(_ link: AppExternalLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func settingsButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 40, alignment: .center)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appPrimary.opacity(0.6))
            }
            .padding(16)
            .appDepthCard(cornerRadius: 18, elevated: false)
        }
        .buttonStyle(.plain)
        .frame(minHeight: GameConstants.minTapTarget)
    }
}
