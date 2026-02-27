//
//  KPIGrid.swift
//  MovieMemo
//

import SwiftUI

struct KPIGrid: View {
    let data: InsightsData

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            KPICard(
                icon: "film",
                color: .blue,
                title: "Movies",
                mainValue: "\(data.moviesCount)",
                subtext: comparisonText(data.moviesComparison, period: data.dateRange.previousPeriodLabel),
                subtextColor: deltaColor(data.moviesComparison.direction),
                emptyMessage: data.moviesCount == 0 ? "No movies yet" : nil,
                detailTitle: "Movies Watched",
                detailBody: "Total movies logged in the selected period. Comparison is versus the same-length prior period.",
                dateRange: data.dateRange
            )

            KPICard(
                icon: "clock",
                color: .purple,
                title: "Watch Time",
                mainValue: formatDuration(data.totalWatchTimeMinutes),
                subtext: data.totalWatchTimeMinutes > 0
                    ? "avg \(formatDuration(data.avgWatchTimePerMovieMinutes))/movie"
                    : nil,
                subtextColor: .secondary,
                emptyMessage: data.totalWatchTimeMinutes == 0 ? "No durations logged" : nil,
                detailTitle: "Watch Time",
                detailBody: "Total watch time is the sum of all logged durations in this period. Average is total ÷ movies with a duration.",
                dateRange: data.dateRange
            )

            if data.hasSpendData {
                KPICard(
                    icon: "dollarsign.circle",
                    color: .green,
                    title: "Spent",
                    mainValue: formatCents(data.totalSpentCents),
                    subtext: data.avgSpentPerMovieCents > 0
                        ? "avg \(formatCents(data.avgSpentPerMovieCents))/movie"
                        : nil,
                    subtextColor: .secondary,
                    emptyMessage: nil,
                    detailTitle: "Total Spent",
                    detailBody: "Sum of all spend amounts logged in this period. Average excludes movies with no spend tracked.",
                    dateRange: data.dateRange
                )
            } else {
                KPICard(
                    icon: "dollarsign.circle",
                    color: .green,
                    title: "Spent",
                    mainValue: "—",
                    subtext: nil,
                    subtextColor: .secondary,
                    emptyMessage: "Start tracking spend to unlock",
                    detailTitle: "Spending",
                    detailBody: "Track spend when logging a movie to see total and average costs here.",
                    dateRange: data.dateRange
                )
            }

            KPICard(
                icon: "flame",
                color: .orange,
                title: "Streak",
                mainValue: data.currentStreakWeeks > 0 ? "\(data.currentStreakWeeks)w" : "0",
                subtext: data.bestStreakWeeks > 0
                    ? "best: \(data.bestStreakWeeks)w"
                    : nil,
                subtextColor: .secondary,
                emptyMessage: data.currentStreakWeeks == 0 ? "No active streak" : nil,
                detailTitle: "Watch Streak",
                detailBody: "A streak counts consecutive calendar weeks where you watched at least one movie. Best streak is your all-time longest run.",
                dateRange: data.dateRange
            )
        }
    }

    // MARK: - Helpers

    private func comparisonText(_ comparison: PeriodComparison, period: String) -> String? {
        guard comparison.previous > 0 || comparison.current > 0 else { return nil }
        return "vs \(period): \(comparison.deltaText)"
    }

    private func deltaColor(_ direction: PeriodComparison.Direction) -> Color {
        switch direction {
        case .up:   return .green
        case .down: return .red
        case .flat: return .secondary
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        let days = minutes / 1440
        let hours = (minutes % 1440) / 60
        let mins = minutes % 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }

    private func formatCents(_ cents: Int) -> String {
        String(format: "$%.2f", Double(cents) / 100.0)
    }
}

// MARK: - KPI Card

struct KPICard: View {
    let icon: String
    let color: Color
    let title: String
    let mainValue: String
    let subtext: String?
    let subtextColor: Color
    let emptyMessage: String?
    let detailTitle: String
    let detailBody: String
    let dateRange: InsightsDateRange

    @State private var showDetail = false
    @State private var displayValue: String = "0"

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.subheadline)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }

                if let empty = emptyMessage {
                    Text(empty)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(displayValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.6), value: displayValue)
                }

                if let sub = subtext {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(subtextColor)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .insightDetailsSheet(isPresented: $showDetail, title: detailTitle, body: detailBody, dateRange: dateRange)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(duration: 0.8)) {
                    displayValue = mainValue
                }
            }
        }
        .onChange(of: mainValue) { _, new in
            withAnimation(.spring(duration: 0.5)) {
                displayValue = new
            }
        }
    }
}
