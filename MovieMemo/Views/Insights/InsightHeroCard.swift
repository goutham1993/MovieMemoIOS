//
//  InsightHeroCard.swift
//  MovieMemo
//

import SwiftUI

struct InsightHeroCard: View {
    let data: InsightsData
    @State private var showDetail = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showDetail = true
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .insightDetailsSheet(
            isPresented: $showDetail,
            title: heroTitle,
            body: heroDetailBody,
            dateRange: data.dateRange
        )

    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(data.dateRange.displayName, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(heroTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: heroIcon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text(heroSubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Label("How is this calculated?", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(heroGradient, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: heroColor.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: - Computed Properties

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [heroColor, heroColor.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroColor: Color {
        switch data.heroType {
        case .volumeTrend(_, let delta, _):
            return delta >= 0 ? .blue : .indigo
        case .timeOfDay:        return .purple
        case .spending:         return .green
        case .justStarting:     return .teal
        }
    }

    private var heroIcon: String {
        switch data.heroType {
        case .volumeTrend(_, let delta, _):
            return delta >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
        case .timeOfDay(let period, _, _):
            switch period.lowercased() {
            case "night":       return "moon.stars.fill"
            case "morning":     return "sunrise.fill"
            case "afternoon":   return "sun.max.fill"
            default:            return "sunset.fill"
            }
        case .spending:         return "dollarsign.circle.fill"
        case .justStarting:     return "film.stack"
        }
    }

    private var heroTitle: String {
        switch data.heroType {
        case .volumeTrend(let count, _, _):
            let word = count == 1 ? "movie" : "movies"
            return "You watched \(count) \(word)"
        case .timeOfDay(let period, _, _):
            return "You're a \(period) watcher"
        case .spending(let total, _):
            return "You spent \(formatCents(total))"
        case .justStarting(let count):
            let word = count == 1 ? "movie" : "movies"
            return "So far, \(count) \(word)"
        }
    }

    private var heroSubtitle: String {
        switch data.heroType {
        case .volumeTrend(_, let delta, let period):
            if delta == 0 { return "Same as \(period)" }
            let sign = delta > 0 ? "+" : ""
            let arrow = delta > 0 ? "📈" : "📉"
            return "That's \(sign)\(delta) vs \(period) \(arrow)"
        case .timeOfDay(_, let pct, _):
            return "\(pct)% of your movies are at this time"
        case .spending(_, let avg):
            return "Avg \(formatCents(avg)) per movie"
        case .justStarting:
            return "Keep watching to unlock more insights!"
        }
    }

    private var heroDetailBody: String {
        switch data.heroType {
        case .volumeTrend:
            return "Shows the total number of movies watched in the selected period compared to the same-length prior period. For 'This Month', the prior period is last calendar month."
        case .timeOfDay(let period, let pct, _):
            return "'\(period)' is the time of day you selected most often when logging movies (\(pct)% of your entries in this period). Times are logged manually when you add a movie."
        case .spending:
            return "Total spend is the sum of all spend amounts logged in this period. Average is total divided by movies watched. Only movies with a spend amount are included."
        case .justStarting:
            return "Once you have 5 or more movies logged, you'll see richer insights including trends, habits, and patterns."
        }
    }

    private func formatCents(_ cents: Int) -> String {
        String(format: "$%.2f", Double(cents) / 100.0)
    }
}
