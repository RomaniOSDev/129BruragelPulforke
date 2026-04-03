//
//  AppPrimaryButton.swift
//  129BruragelPulforke
//

import SwiftUI

struct AppPrimaryButton: View {
    let title: String
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary
        case surface
    }

    private let corner: CGFloat = 14

    var body: some View {
        Button(action: action) {
            label
                .modifier(DepthButtonStyle(style: style, corner: corner))
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appTextPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .frame(minHeight: GameConstants.minTapTarget)
    }
}

private struct DepthButtonStyle: ViewModifier {
    let style: AppPrimaryButton.Style
    let corner: CGFloat

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            content.appDepthPrimaryCapsule(cornerRadius: corner)
        case .surface:
            content.appDepthSecondaryCapsule(cornerRadius: corner)
        }
    }
}

struct AppSecondaryButton: View {
    let title: String
    let action: () -> Void

    private let corner: CGFloat = 14

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: GameConstants.minTapTarget)
                .appDepthSecondaryCapsule(cornerRadius: corner)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
