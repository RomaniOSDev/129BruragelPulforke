//
//  OnboardingView.swift
//  129BruragelPulforke
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            OnboardingHeroPage(
                title: "Move with Instinct",
                subtitle: "Swipe, dodge, and push through shifting hazards in real time.",
                illustration: .burst
            )
            .tag(0)

            OnboardingHeroPage(
                title: "Strike with Precision",
                subtitle: "Drag into position, time every shot, and keep the pressure high.",
                illustration: .orbit
            )
            .tag(1)

            OnboardingHeroPage(
                title: "Earn Every Star",
                subtitle: "Clear stages, chase sharp scores, and beat the clock for three stars.",
                illustration: .constellation,
                showsCTA: true,
                onFinish: { store.setOnboardingSeen() }
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .appScreenBackdrop()
    }
}

private enum IllustrationKind {
    case burst
    case orbit
    case constellation
}

private struct OnboardingHeroPage: View {
    let title: String
    let subtitle: String
    let illustration: IllustrationKind
    var showsCTA: Bool = false
    var onFinish: (() -> Void)?

    @State private var animate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                illustrationView
                    .padding(24)
                    .frame(height: 260)
                    .padding(.horizontal, GameConstants.horizontalPadding)
                    .appDepthCard(cornerRadius: 28, elevated: true)
                .scaleEffect(animate ? 1 : 0.92)
                .opacity(animate ? 1 : 0.75)
                .animation(.spring(response: 0.55, dampingFraction: 0.82), value: animate)

                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.title.bold())
                        .foregroundStyle(Color.appTextPrimary)
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.horizontal, GameConstants.horizontalPadding)

                if showsCTA {
                    AppPrimaryButton(title: "Enter the Action") {
                        onFinish?()
                    }
                    .padding(.horizontal, GameConstants.horizontalPadding)
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            animate = true
        }
    }

    @ViewBuilder
    private var illustrationView: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width
                let h = size.height
                switch illustration {
                case .burst:
                    drawBurst(ctx: ctx, w: w, h: h, t: t)
                case .orbit:
                    drawOrbit(ctx: ctx, w: w, h: h, t: t)
                case .constellation:
                    drawConstellation(ctx: ctx, w: w, h: h, t: t)
                }
            }
        }
    }

    private func drawBurst(ctx: GraphicsContext, w: CGFloat, h: CGFloat, t: TimeInterval) {
        let center = CGPoint(x: w * 0.5, y: h * 0.55)
        for i in 0..<7 {
            let a = (Double(i) / 7.0) * Double.pi * 2 + t * 1.1
            let r = 40 + CGFloat(i) * 6 + CGFloat(sin(t * 2 + Double(i))) * 6
            var p = Path()
            p.move(to: center)
            p.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r))
            ctx.stroke(p, with: .color(Color.appAccent), lineWidth: 4)
        }
        var hero = Path(ellipseIn: CGRect(x: center.x - 22, y: center.y - 22, width: 44, height: 44))
        ctx.fill(hero, with: .color(Color.appPrimary.opacity(0.9)))
    }

    private func drawOrbit(ctx: GraphicsContext, w: CGFloat, h: CGFloat, t: TimeInterval) {
        let center = CGPoint(x: w * 0.5, y: h * 0.5)
        var ring = Path(ellipseIn: CGRect(x: center.x - 70, y: center.y - 70, width: 140, height: 140))
        ctx.stroke(ring, with: .color(Color.appAccent.opacity(0.8)), lineWidth: 3)
        let a = t * 1.6
        let dot = CGPoint(x: center.x + CGFloat(cos(a)) * 70, y: center.y + CGFloat(sin(a)) * 70)
        var projectile = Path(ellipseIn: CGRect(x: dot.x - 8, y: dot.y - 8, width: 16, height: 16))
        ctx.fill(projectile, with: .color(Color.appPrimary))
    }

    private func drawConstellation(ctx: GraphicsContext, w: CGFloat, h: CGFloat, t: TimeInterval) {
        let pts: [CGPoint] = [
            CGPoint(x: w * 0.2, y: h * 0.75),
            CGPoint(x: w * 0.45, y: h * 0.35),
            CGPoint(x: w * 0.7, y: h * 0.6),
            CGPoint(x: w * 0.85, y: h * 0.25),
        ]
        for i in 0..<(pts.count - 1) {
            var p = Path()
            p.move(to: pts[i])
            p.addLine(to: pts[i + 1])
            let alpha = 0.35 + 0.35 * sin(t * 2 + Double(i))
            ctx.stroke(p, with: .color(Color.appAccent.opacity(min(0.95, max(0.2, alpha)))), lineWidth: 2)
        }
        for (idx, pt) in pts.enumerated() {
            let pulse = 6 + CGFloat(sin(t * 3 + Double(idx))) * 3
            var star = Path(ellipseIn: CGRect(x: pt.x - pulse, y: pt.y - pulse, width: pulse * 2, height: pulse * 2))
            ctx.fill(star, with: .color(idx == pts.count - 1 ? Color.appPrimary : Color.appAccent.opacity(0.65)))
        }
    }
}
