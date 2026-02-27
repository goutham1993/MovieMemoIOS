//
//  TrendsChartCard.swift
//  MovieMemo
//

import SwiftUI
import Charts

struct TrendsChartCard: View {
    let data: InsightsData
    @State private var selectedMetric: InsightsChartMetric = .movies
    @State private var showDetail = false

    private var availableMetrics: [InsightsChartMetric] {
        var metrics: [InsightsChartMetric] = [.movies]
        if data.hasSpendData { metrics.append(.spend) }
        if data.totalWatchTimeMinutes > 0 { metrics.append(.watchTime) }
        return metrics
    }

    private var chartBuckets: [MonthBucket] {
        data.monthlyBuckets
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            if availableMetrics.count > 1 {
                metricToggle
            }
            if chartBuckets.count < 2 {
                emptyChartView
            } else {
                chartView
                chartSummary
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .insightDetailsSheet(
            isPresented: $showDetail,
            title: "Trends",
            body: "Shows monthly totals for the selected metric across all recorded history. Buckets are calendar months. Spend and Watch Time only appear if at least one movie has that data.",
            dateRange: data.dateRange
        )
    }

    // MARK: - Sub-views

    private var headerRow: some View {
        HStack {
            Label("Trends", systemImage: "chart.xyaxis.line")
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showDetail = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var metricToggle: some View {
        HStack(spacing: 8) {
            ForEach(availableMetrics) { metric in
                MetricChip(
                    metric: metric,
                    isSelected: selectedMetric == metric
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedMetric = metric
                    }
                }
            }
        }
    }

    private var chartView: some View {
        Chart(chartBuckets) { bucket in
            BarMark(
                x: .value("Month", bucket.displayMonth),
                y: .value(selectedMetric.rawValue, yValue(for: bucket))
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.caption2)
                AxisGridLine()
            }
        }
        .frame(height: 160)
        .animation(.easeInOut(duration: 0.4), value: selectedMetric)
    }

    private var emptyChartView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(.quaternary)
            Text("Watch more to see trends")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    private var chartSummary: some View {
        let values = chartBuckets.map { yValue(for: $0) }
        let peak = values.max() ?? 0
        let peakBucket = chartBuckets.first(where: { yValue(for: $0) == peak })
        let avg = values.isEmpty ? 0.0 : values.reduce(0.0, +) / Double(values.count)
        return TrendsSummaryRow(
            peakLabel: peakBucket?.shortLabel ?? "—",
            peakValue: formatValue(peak),
            avgValue: formatValue(avg)
        )
    }

    // MARK: - Helpers

    private func yValue(for bucket: MonthBucket) -> Double {
        switch selectedMetric {
        case .movies:    return Double(bucket.count)
        case .spend:     return Double(bucket.spendCents) / 100.0
        case .watchTime: return Double(bucket.watchMinutes) / 60.0
        }
    }

    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case .movies:    return "\(Int(value))"
        case .spend:     return String(format: "$%.0f", value)
        case .watchTime: return String(format: "%.1fh", value)
        }
    }
}

// MARK: - Metric Chip (extracted to avoid type-checker overload)

private struct MetricChip: View {
    let metric: InsightsChartMetric
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(metric.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(chipBackground, in: Capsule())
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private var chipBackground: Color {
        isSelected ? Color.accentColor.opacity(0.15) : Color.clear
    }
}

// MARK: - Summary Row (extracted to avoid type-checker overload)

private struct TrendsSummaryRow: View {
    let peakLabel: String
    let peakValue: String
    let avgValue: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Peak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(peakLabel) (\(peakValue))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Divider().frame(height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("Monthly avg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(avgValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}
