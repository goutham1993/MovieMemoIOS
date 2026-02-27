//
//  TimeOfDayDistributionCard.swift
//  MovieMemo
//

import SwiftUI

struct TimeOfDayDistributionCard: View {
    let data: InsightsData
    @State private var showDetail = false
    @State private var animateBars = false

    private var total: Int {
        data.timeOfDayBuckets.map { $0.count }.reduce(0, +)
    }

    private var dominant: KeyCount? { data.timeOfDayBuckets.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Time of Day", systemImage: "clock")
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

            if data.timeOfDayBuckets.isEmpty {
                emptyState
            } else {
                // Bars
                VStack(spacing: 12) {
                    ForEach(data.timeOfDayBuckets) { bucket in
                        TimeOfDayRow(
                            bucket: bucket,
                            total: total,
                            animate: animateBars
                        )
                    }
                }

                // Insight line
                if let dom = dominant, total > 0 {
                    let pct = Int(Double(dom.count) / Double(total) * 100)
                    insightLine("You mostly watch at \(dom.category.lowercased()) (\(pct)%).", icon: "lightbulb")
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .insightDetailsSheet(
            isPresented: $showDetail,
            title: "Time of Day",
            body: "Distribution of movies by the time of day you logged them: Morning (before noon), Afternoon (noon–6pm), Evening (6pm–9pm), Night (after 9pm). Based on the time-of-day field you select when logging.",
            dateRange: data.dateRange
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.7)) { animateBars = true }
            }
        }
        .onChange(of: data.dateRange) { _, _ in
            animateBars = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.7)) { animateBars = true }
            }
        }
    }

    private var emptyState: some View {
        Text("No data for this period")
            .font(.subheadline)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }
}

// MARK: - Row

private struct TimeOfDayRow: View {
    let bucket: KeyCount
    let total: Int
    let animate: Bool

    private var percent: Double {
        total > 0 ? Double(bucket.count) / Double(total) : 0
    }

    private var displayPercent: Int { Int(percent * 100) }

    private var icon: String {
        switch bucket.category.lowercased() {
        case "morning":     return "sunrise.fill"
        case "afternoon":   return "sun.max.fill"
        case "evening":     return "sunset.fill"
        default:            return "moon.stars.fill"
        }
    }

    private var barColor: Color {
        switch bucket.category.lowercased() {
        case "morning":     return .orange
        case "afternoon":   return .yellow
        case "evening":     return .indigo
        default:            return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(barColor)
                    .font(.caption)
                Text(bucket.category)
                    .font(.subheadline)
                Spacer()
                Text("\(displayPercent)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text("(\(bucket.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    Capsule()
                        .fill(barColor.gradient)
                        .frame(width: animate ? geo.size.width * percent : 0, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Insight Line Helper

func insightLine(_ text: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
        Image(systemName: icon)
            .foregroundStyle(Color.accentColor)
            .font(.caption)
            .padding(.top, 2)
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
}
