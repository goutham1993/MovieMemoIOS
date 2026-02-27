//
//  InsightsModels.swift
//  MovieMemo
//

import Foundation

// MARK: - Date Range

enum InsightsDateRange: Equatable, Hashable {
    case thisMonth
    case last3Months
    case thisYear
    case allTime
    case custom(Date, Date)

    static let segments: [InsightsDateRange] = [.thisMonth, .last3Months, .thisYear, .allTime]

    var displayName: String {
        switch self {
        case .thisMonth:    return "This Month"
        case .last3Months:  return "3 Months"
        case .thisYear:     return "This Year"
        case .allTime:      return "All Time"
        case .custom:       return "Custom"
        }
    }

    var storageKey: String {
        switch self {
        case .thisMonth:    return "thisMonth"
        case .last3Months:  return "last3Months"
        case .thisYear:     return "thisYear"
        case .allTime:      return "allTime"
        case .custom(let s, let e):
            return "custom_\(Int(s.timeIntervalSince1970))_\(Int(e.timeIntervalSince1970))"
        }
    }

    var segmentIndex: Int {
        switch self {
        case .thisMonth:    return 0
        case .last3Months:  return 1
        case .thisYear:     return 2
        case .allTime:      return 3
        case .custom:       return -1
        }
    }

    func dateInterval() -> DateInterval {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .thisMonth:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let end = cal.date(byAdding: DateComponents(month: 1, second: -1), to: start)!
            return DateInterval(start: start, end: end)
        case .last3Months:
            let start = cal.date(byAdding: .month, value: -3, to: now)!
            return DateInterval(start: start, end: now)
        case .thisYear:
            let start = cal.date(from: cal.dateComponents([.year], from: now))!
            return DateInterval(start: start, end: now)
        case .allTime:
            return DateInterval(start: Date.distantPast, end: now)
        case .custom(let start, let end):
            return DateInterval(start: start, end: end)
        }
    }

    func previousInterval() -> DateInterval? {
        let cal = Calendar.current
        let current = dateInterval()
        switch self {
        case .thisMonth:
            let prevStart = cal.date(byAdding: .month, value: -1, to: current.start)!
            let prevEnd = cal.date(byAdding: .second, value: -1, to: current.start)!
            return DateInterval(start: prevStart, end: prevEnd)
        case .last3Months, .custom:
            let duration = current.duration
            let prevEnd = current.start
            let prevStart = prevEnd.addingTimeInterval(-duration)
            return DateInterval(start: prevStart, end: prevEnd)
        case .thisYear:
            let prevStart = cal.date(byAdding: .year, value: -1, to: current.start)!
            let prevEnd = cal.date(byAdding: .second, value: -1, to: current.start)!
            return DateInterval(start: prevStart, end: prevEnd)
        case .allTime:
            return nil
        }
    }

    var previousPeriodLabel: String {
        switch self {
        case .thisMonth:    return "last month"
        case .last3Months:  return "prior 3 months"
        case .thisYear:     return "last year"
        case .allTime:      return "all time"
        case .custom:       return "prior period"
        }
    }
}

// MARK: - Period Comparison

struct PeriodComparison: Equatable {
    let current: Int
    let previous: Int

    var delta: Int { current - previous }

    var deltaPercent: Double {
        guard previous > 0 else { return current > 0 ? 100 : 0 }
        return Double(delta) / Double(previous) * 100
    }

    var direction: Direction {
        if delta > 0 { return .up }
        if delta < 0 { return .down }
        return .flat
    }

    enum Direction: Equatable { case up, down, flat }

    var deltaText: String {
        switch direction {
        case .up:   return "+\(delta)"
        case .down: return "\(delta)"
        case .flat: return "±0"
        }
    }

    var percentText: String {
        let pct = deltaPercent
        guard !pct.isInfinite, !pct.isNaN else { return "" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(pct))%"
    }
}

// MARK: - Month Bucket

struct MonthBucket: Identifiable, Equatable {
    let id = UUID()
    let yearMonth: String
    let count: Int
    let spendCents: Int
    let watchMinutes: Int

    var displayMonth: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        guard let date = fmt.date(from: yearMonth) else { return yearMonth }
        let out = DateFormatter()
        out.dateFormat = "MMM"
        return out.string(from: date)
    }

    var shortLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        guard let date = fmt.date(from: yearMonth) else { return yearMonth }
        let out = DateFormatter()
        out.dateFormat = "MMM yy"
        return out.string(from: date)
    }
}

// MARK: - Smart Insight

struct SmartInsight: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let icon: String
    let detailTitle: String
    let detailBody: String
}

// MARK: - Hero Insight Type

enum HeroInsightType: Equatable {
    case volumeTrend(count: Int, delta: Int, period: String)
    case timeOfDay(period: String, percent: Int, count: Int)
    case spending(totalCents: Int, avgCents: Int)
    case justStarting(count: Int)
}

// MARK: - Chart Metric

enum InsightsChartMetric: String, CaseIterable, Identifiable {
    case movies     = "Movies"
    case spend      = "Spend"
    case watchTime  = "Watch Time"

    var id: String { rawValue }
}

// MARK: - Insights Data

struct InsightsData: Equatable {
    let dateRange: InsightsDateRange
    let heroType: HeroInsightType

    // Volume
    let moviesCount: Int
    let moviesComparison: PeriodComparison

    // Watch time
    let totalWatchTimeMinutes: Int
    let avgWatchTimePerMovieMinutes: Int

    // Spend
    let totalSpentCents: Int
    let avgSpentPerMovieCents: Int
    let theaterAvgSpendCents: Int
    let hasSpendData: Bool

    // Location
    let theaterCount: Int
    let homeCount: Int
    let friendsHomeCount: Int
    let otherCount: Int

    // Day split
    let weekdayCount: Int
    let weekendCount: Int

    // Distributions (sorted by count desc)
    let timeOfDayBuckets: [KeyCount]
    let topGenres: [KeyCount]
    let topLanguages: [KeyCount]
    let companions: [KeyCount]

    // Trend chart
    let monthlyBuckets: [MonthBucket]

    // Streaks (all-time)
    let currentStreakWeeks: Int
    let bestStreakWeeks: Int

    // Narrative
    let smartInsights: [SmartInsight]

    // All-time total for edge-case detection
    let totalAllTimeEntries: Int
}
