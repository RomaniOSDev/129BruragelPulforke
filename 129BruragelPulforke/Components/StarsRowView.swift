//
//  StarsRowView.swift
//  129BruragelPulforke
//

import SwiftUI

struct StarsRowView: View {
    let filled: Int
    let maxStars: Int
    var glow: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<maxStars, id: \.self) { i in
                starGlyph(filled: i < filled)
            }
        }
    }

    private func starGlyph(filled: Bool) -> some View {
        ZStack {
            if glow, filled {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.appAccent.opacity(0.45))
                    .blur(radius: 6)
                    .scaleEffect(1.2)
            }
            Image(systemName: filled ? "star.fill" : "star")
                .foregroundStyle(filled ? Color.appAccent : Color.appTextSecondary.opacity(0.45))
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel(filled ? "Star earned" : "Star locked")
    }
}
