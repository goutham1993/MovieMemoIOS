//
//  PremiumHintPreviewView.swift
//  MovieMemo
//

import SwiftUI

/// A soft blurred stack of premium cards with a locked front card.
/// Used on onboarding page 5 as a non-aggressive premium hint — not a paywall.
struct PremiumHintPreviewView: View {
    var body: some View {
        ZStack(alignment: .center) {

            // Back card — most blurred, lowest opacity
            ghostCard(scale: 0.82, offsetY: 36, blurRadius: 7, opacity: 0.30)

            // Middle card — slightly blurred
            ghostCard(scale: 0.91, offsetY: 18, blurRadius: 3, opacity: 0.52)

            // Front locked card — fully visible
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color.premiumGold)

                Text("Premium Insights")
                    .font(AppFont.sectionTitle)
                    .foregroundColor(Theme.primaryText)

                Text("Your full cinema story awaits.")
                    .font(AppFont.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 116)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Color.premiumGold.opacity(0.38), lineWidth: 1)
            )
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Ghost Card

    private func ghostCard(
        scale: CGFloat,
        offsetY: CGFloat,
        blurRadius: CGFloat,
        opacity: Double
    ) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Theme.surface)
            .frame(height: 116)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Color.premiumGold.opacity(0.10), lineWidth: 1)
            )
            .scaleEffect(scale)
            .offset(y: offsetY)
            .blur(radius: blurRadius)
            .opacity(opacity)
            .padding(.horizontal, Theme.Spacing.xl)
    }
}
