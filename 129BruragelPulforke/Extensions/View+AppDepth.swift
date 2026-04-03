//
//  View+AppDepth.swift
//  129BruragelPulforke
//

import SwiftUI

enum AppDepthStyle {
    static let cardRadius: CGFloat = 20
    static let panelRadius: CGFloat = 22
    static let chipRadius: CGFloat = 14
}

extension View {

    /// Full-screen layered backdrop (gradients only from app palette).
    func appScreenBackdrop() -> some View {
        background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.appBackground,
                        Color.appSurface.opacity(0.28),
                        Color.appBackground,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color.appPrimary.opacity(0.2), Color.clear],
                    center: UnitPoint(x: 0.12, y: 0.08),
                    startRadius: 30,
                    endRadius: 340
                )
                RadialGradient(
                    colors: [Color.appAccent.opacity(0.12), Color.clear],
                    center: UnitPoint(x: 0.92, y: 0.88),
                    startRadius: 60,
                    endRadius: 300
                )
            }
            .ignoresSafeArea()
        }
    }

    /// Raised card: volumetric gradient fill, rim light, dual shadow.
    func appDepthCard(cornerRadius: CGFloat = AppDepthStyle.cardRadius, elevated: Bool = true) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface,
                                Color.appSurface.opacity(0.78),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appTextPrimary.opacity(0.07),
                                Color.clear,
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appTextPrimary.opacity(0.12),
                                Color.appAccent.opacity(0.28),
                                Color.appPrimary.opacity(0.24),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.appPrimary.opacity(elevated ? 0.2 : 0.09), radius: elevated ? 18 : 9, x: 0, y: elevated ? 10 : 5)
            .shadow(color: Color.appBackground.opacity(0.65), radius: elevated ? 6 : 3, x: 0, y: elevated ? 4 : 2)
        }
    }

    /// Inset playfield / panel — deeper, darker pocket with inner glow edge.
    func appDepthInsetPanel(cornerRadius: CGFloat = AppDepthStyle.panelRadius) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface,
                                Color.appBackground.opacity(0.55),
                                Color.appSurface.opacity(0.92),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appPrimary.opacity(0.35),
                                Color.appAccent.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.appBackground.opacity(0.85), radius: 8, x: 0, y: 4)
            .shadow(color: Color.appPrimary.opacity(0.12), radius: 12, x: 0, y: 6)
        }
    }

    /// Primary CTA fill — gradient + specular strip + drop shadow.
    func appDepthPrimaryCapsule(cornerRadius: CGFloat = 14) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appTextPrimary.opacity(0.22), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
            .shadow(color: Color.appPrimary.opacity(0.45), radius: 10, x: 0, y: 5)
            .shadow(color: Color.appAccent.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }

    /// Secondary / surface button.
    func appDepthSecondaryCapsule(cornerRadius: CGFloat = 14) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface, Color.appSurface.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.appBackground.opacity(0.5), radius: 6, x: 0, y: 3)
        }
    }

    /// Selected difficulty / pill — green gradient when selected.
    func appDepthDifficultyPill(selected: Bool) -> some View {
        background {
            Group {
                if selected {
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(0.95), Color.appPrimary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appTextPrimary.opacity(0.18), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                    .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, x: 0, y: 4)
                } else {
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appSurface, Color.appSurface.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Capsule()
                            .stroke(Color.appTextSecondary.opacity(0.25), lineWidth: 1)
                    }
                    .shadow(color: Color.appBackground.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
        }
    }

    func appTabBarChrome() -> some View {
        self
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color.appSurface.opacity(0.94), for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
    }
}
