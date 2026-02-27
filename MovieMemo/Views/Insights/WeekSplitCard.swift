//
//  WeekSplitCard.swift
//  MovieMemo
//

import SwiftUI

struct WeekSplitCard: View {
    let data: InsightsData
    @State private var showDetail = false
    @State private var animateBars = false

    private var total: Int { data.weekdayCount + data.weekendCount }

    private var weekdayPercent: Double {
        total > 0 ? Double(data.weekdayCount) / Double(total) : 0
    }
    private var weekendPercent: Double {
        total > 0 ? Double(data.weekendCount) / Double(total) : 0
    }

    private var insightText: String {
        guard total > 0 else { return "No data yet." }
        if data.weekdayCount > data.weekendCount {
            let pct = Int(weekdayPercent * 100)
            return "More weekday watching (\(pct)%) — likely after work."
        } else if data.weekendCount > data.weekdayCount {
            let pct = Int(weekendPercent * 100)
            return "You're a weekend watcher (\(pct)% on weekends)."
        } else {
            return "You watch equally on weekdays and weekends."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Weekday vs Weekend", systemImage: "calendar")
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

            if total == 0 {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    splitRow(label: "Weekday", count: data.weekdayCount, percent: weekdayPercent, color: .blue)
                    splitRow(label: "Weekend", count: data.weekendCount, percent: weekendPercent, color: .orange)
                }

                insightLine(insightText, icon: "lightbulb")
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .insightDetailsSheet(
            isPresented: $showDetail,
            title: "Weekday vs Weekend",
            body: "Splits movies by whether the watched date falls on a weekday (Mon–Fri) or weekend (Sat–Sun). Based on the date you log, not the showtime.",
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

    private func splitRow(label: String, count: Int, percent: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(percent * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surface2)
                        .frame(height: 10)
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: animateBars ? geo.size.width * percent : 0, height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}
