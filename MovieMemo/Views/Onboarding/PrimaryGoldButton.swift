//
//  PrimaryGoldButton.swift
//  MovieMemo
//

import SwiftUI

/// 56pt height, 28pt corner radius gold CTA button with medium haptic feedback.
struct PrimaryGoldButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "0F0F12"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.premiumGold)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        }
        .buttonStyle(CinematicScaleButtonStyle())
    }
}
