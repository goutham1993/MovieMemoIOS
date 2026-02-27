//
//  SmartInsightsList.swift
//  MovieMemo
//

import SwiftUI

struct SmartInsightsList: View {
    let insights: [SmartInsight]
    let dateRange: InsightsDateRange
    @State private var selectedInsight: SmartInsight?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Smart Insights", systemImage: "sparkles")
                .font(.title3)
                .fontWeight(.bold)

            if insights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 28))
                        .foregroundStyle(.quaternary)
                    Text("Watch more movies to unlock insights")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(insights.enumerated()), id: \.element.id) { idx, insight in
                        InsightBulletRow(insight: insight) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedInsight = insight
                        }
                        if idx < insights.count - 1 {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .sheet(item: $selectedInsight) { insight in
            InsightDetailsSheet(
                title: insight.detailTitle,
                bodyText: insight.detailBody,
                dateRange: dateRange
            )
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Bullet Row

private struct InsightBulletRow: View {
    let insight: SmartInsight
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: insight.icon)
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tap to learn more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
