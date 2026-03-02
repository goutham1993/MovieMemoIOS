//
//  MockChartPreviewView.swift
//  MovieMemo
//

import SwiftUI

/// Minimal monochrome/gold bar chart preview used on the Patterns onboarding page.
/// Weekend bars are highlighted in full gold; weekday bars use a muted gold tint.
struct MockChartPreviewView: View {

    private struct Bar: Identifiable {
        let id: Int
        let label: String
        let ratio: Double
        let highlight: Bool
    }

    private let bars: [Bar] = [
        Bar(id: 0, label: "M", ratio: 0.30, highlight: false),
        Bar(id: 1, label: "T", ratio: 0.50, highlight: false),
        Bar(id: 2, label: "W", ratio: 0.22, highlight: false),
        Bar(id: 3, label: "T", ratio: 0.75, highlight: false),
        Bar(id: 4, label: "F", ratio: 0.55, highlight: false),
        Bar(id: 5, label: "S", ratio: 1.00, highlight: true),
        Bar(id: 6, label: "S", ratio: 0.88, highlight: true)
    ]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(bars) { bar in
                VStack(spacing: Theme.Spacing.xs) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            bar.highlight
                                ? Color.premiumGold
                                : Color.premiumGold.opacity(0.28)
                        )
                        .frame(width: 30, height: CGFloat(bar.ratio) * 88)

                    Text(bar.label)
                        .font(AppFont.caption)
                        .foregroundColor(
                            bar.highlight
                                ? Color.premiumGold.opacity(0.85)
                                : Theme.tertiaryText
                        )
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .padding(.vertical, Theme.Spacing.md)
    }
}
