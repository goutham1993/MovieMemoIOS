//
//  InsightPreviewCardView.swift
//  MovieMemo
//

import SwiftUI

/// A single mock insight card used on the Insights onboarding page.
/// Shows static example data to communicate the value of the feature.
struct InsightPreviewCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {

            // Header row
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.premiumGold)

                Text("This Month")
                    .font(AppFont.caption)
                    .foregroundColor(Theme.secondaryText)

                Spacer()

                Text("Jan 2025")
                    .font(AppFont.caption)
                    .foregroundColor(Theme.tertiaryText)
            }

            // Primary stat
            Text("You watched **18 movies** last month.")
                .font(AppFont.body)
                .foregroundColor(Theme.primaryText)

            Rectangle()
                .fill(Theme.divider)
                .frame(height: 1)

            // Secondary insight
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.premiumGold.opacity(0.75))

                Text("Weekends are your peak time.")
                    .font(AppFont.caption)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Color.premiumGold.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, Theme.Spacing.xl)
    }
}
