//
//  InsightsViewModel.swift
//  MovieMemo
//

import Foundation
import Observation

@Observable
@MainActor
final class InsightsViewModel {

    // MARK: - Published State

    var selectedRange: InsightsDateRange = .thisMonth
    var insightsData: InsightsData?
    var isLoading = false
    var showCustomRangePicker = false
    var customRangeStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var customRangeEnd: Date = Date()

    // MARK: - Private

    private let repository: MovieRepository
    private var cachedData: [String: InsightsData] = [:]

    // MARK: - Init

    init(repository: MovieRepository) {
        self.repository = repository
        loadPersistedRange()
        loadInsights()
    }

    // MARK: - Public API

    func selectRange(_ range: InsightsDateRange) {
        selectedRange = range
        saveSelectedRange()
        loadInsights()
    }

    func applyCustomRange() {
        let end = max(customRangeStart, customRangeEnd)
        selectedRange = .custom(customRangeStart, end)
        saveSelectedRange()
        showCustomRangePicker = false
        loadInsights()
    }

    func invalidateAndReload() {
        cachedData.removeAll()
        loadInsights()
    }

    func loadInsights(force: Bool = false) {
        let key = selectedRange.storageKey
        if !force, let cached = cachedData[key] {
            insightsData = cached
            return
        }

        isLoading = true
        let allEntries = repository.getAllWatchedEntries()
        let interval = selectedRange.dateInterval()
        let prevInterval = selectedRange.previousInterval()
        let range = selectedRange

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result = Self.computeInsights(
                allEntries: allEntries,
                interval: interval,
                prevInterval: prevInterval,
                range: range
            )
            DispatchQueue.main.async {
                self.cachedData[key] = result
                self.insightsData = result
                self.isLoading = false
            }
        }
    }

    // MARK: - Persistence

    private func loadPersistedRange() {
        guard let stored = UserDefaults.standard.string(forKey: "InsightsSelectedRange") else { return }
        switch stored {
        case "thisMonth":   selectedRange = .thisMonth
        case "last3Months": selectedRange = .last3Months
        case "thisYear":    selectedRange = .thisYear
        case "allTime":     selectedRange = .allTime
        default:            selectedRange = .thisMonth
        }
    }

    private func saveSelectedRange() {
        switch selectedRange {
        case .thisMonth:    UserDefaults.standard.set("thisMonth",   forKey: "InsightsSelectedRange")
        case .last3Months:  UserDefaults.standard.set("last3Months", forKey: "InsightsSelectedRange")
        case .thisYear:     UserDefaults.standard.set("thisYear",    forKey: "InsightsSelectedRange")
        case .allTime:      UserDefaults.standard.set("allTime",     forKey: "InsightsSelectedRange")
        case .custom:       UserDefaults.standard.set("thisMonth",   forKey: "InsightsSelectedRange")
        }
    }

    // MARK: - Core Computation (nonisolated static for background safety)

    private static func computeInsights(
        allEntries: [WatchedEntry],
        interval: DateInterval,
        prevInterval: DateInterval?,
        range: InsightsDateRange
    ) -> InsightsData {

        let entries = allEntries.filter { isEntry($0, in: interval) }
        let prevEntries = prevInterval.map { pi in allEntries.filter { isEntry($0, in: pi) } } ?? []

        let totalAll = allEntries.count

        // --- Volume ---
        let moviesCount = entries.count
        let moviesComparison = PeriodComparison(current: moviesCount, previous: prevEntries.count)

        // --- Watch Time ---
        let totalWatchTime = entries.compactMap { $0.durationMin }.reduce(0, +)
        let avgWatchTime = moviesCount > 0 ? totalWatchTime / moviesCount : 0

        // --- Spend ---
        let spendEntries = entries.filter { $0.spendCents != nil }
        let hasSpendData = !spendEntries.isEmpty
        let totalSpent = entries.compactMap { $0.spendCents }.reduce(0, +)
        let avgSpent = moviesCount > 0 ? totalSpent / moviesCount : 0
        let theaterEntries = entries.filter { $0.locationTypeEnum == .theater }
        let theaterSpends = theaterEntries.compactMap { $0.spendCents }
        let theaterAvgSpend = theaterSpends.isEmpty ? 0 : theaterSpends.reduce(0, +) / theaterSpends.count

        // --- Location ---
        let theaterCount = entries.filter { $0.locationTypeEnum == .theater }.count
        let homeCount = entries.filter { $0.locationTypeEnum == .home }.count
        let friendsHomeCount = entries.filter { $0.locationTypeEnum == .friendsHome }.count
        let otherCount = entries.filter { $0.locationTypeEnum == .other }.count

        // --- Weekday / Weekend ---
        let cal = Calendar.current
        let weekdayCount = entries.filter { entry in
            guard let date = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) else { return false }
            let wd = cal.component(.weekday, from: date)
            return wd >= 2 && wd <= 6
        }.count
        let weekendCount = moviesCount - weekdayCount

        // --- Time of Day ---
        let timeOfDayBuckets: [KeyCount] = {
            let grouped = Dictionary(grouping: entries, by: { $0.timeOfDayEnum.displayName })
            return grouped.map { KeyCount(category: $0.key, count: $0.value.count) }
                .sorted { $0.count > $1.count }
        }()

        // --- Genres ---
        let topGenres: [KeyCount] = {
            let grouped = Dictionary(grouping: entries.compactMap { $0.genre?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }, by: { $0 })
            return grouped.map { KeyCount(category: $0.key, count: $0.value.count) }
                .sorted { $0.count > $1.count }
        }()

        // --- Languages ---
        let topLanguages: [KeyCount] = {
            let grouped = Dictionary(grouping: entries, by: { $0.languageEnum.displayName })
            return grouped.map { KeyCount(category: $0.key, count: $0.value.count) }
                .sorted { $0.count > $1.count }
        }()

        // --- Companions (each name counted individually) ---
        let companions: [KeyCount] = {
            var companionCounts: [String: Int] = [:]
            for entry in entries {
                if let comp = entry.companions, !comp.isEmpty {
                    let names = comp.components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    for name in names {
                        companionCounts[name, default: 0] += 1
                    }
                }
            }
            return companionCounts.map { KeyCount(category: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
        }()

        // --- Monthly Buckets ---
        let monthlyBuckets: [MonthBucket] = {
            let fmtIn = DateFormatter()
            fmtIn.dateFormat = "yyyy-MM-dd"
            let fmtOut = DateFormatter()
            fmtOut.dateFormat = "yyyy-MM"

            var byMonth: [String: (count: Int, spend: Int, watch: Int)] = [:]
            for entry in allEntries {
                guard let date = fmtIn.date(from: entry.watchedDate) else { continue }
                let key = fmtOut.string(from: date)
                var existing = byMonth[key] ?? (0, 0, 0)
                existing.count += 1
                existing.spend += entry.spendCents ?? 0
                existing.watch += entry.durationMin ?? 0
                byMonth[key] = existing
            }
            return byMonth.map { MonthBucket(yearMonth: $0.key, count: $0.value.count, spendCents: $0.value.spend, watchMinutes: $0.value.watch) }
                .sorted { $0.yearMonth < $1.yearMonth }
        }()

        // --- Streaks (all-time) ---
        let (currentStreak, bestStreak) = calculateStreaks(from: allEntries)

        // --- Smart Insights ---
        let smartInsights = generateSmartInsights(
            entries: entries,
            allEntries: allEntries,
            prevEntries: prevEntries,
            range: range,
            moviesComparison: moviesComparison,
            totalWatchTime: totalWatchTime,
            avgWatchTime: avgWatchTime,
            totalSpent: totalSpent,
            avgSpent: avgSpent,
            topGenres: topGenres,
            timeOfDayBuckets: timeOfDayBuckets,
            weekdayCount: weekdayCount,
            weekendCount: weekendCount,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )

        // --- Hero Type ---
        let heroType = computeHeroType(
            count: moviesCount,
            comparison: moviesComparison,
            timeOfDayBuckets: timeOfDayBuckets,
            hasSpendData: hasSpendData,
            totalSpent: totalSpent,
            avgSpent: avgSpent,
            totalAll: totalAll,
            range: range
        )

        return InsightsData(
            dateRange: range,
            heroType: heroType,
            moviesCount: moviesCount,
            moviesComparison: moviesComparison,
            totalWatchTimeMinutes: totalWatchTime,
            avgWatchTimePerMovieMinutes: avgWatchTime,
            totalSpentCents: totalSpent,
            avgSpentPerMovieCents: avgSpent,
            theaterAvgSpendCents: theaterAvgSpend,
            hasSpendData: hasSpendData,
            theaterCount: theaterCount,
            homeCount: homeCount,
            friendsHomeCount: friendsHomeCount,
            otherCount: otherCount,
            weekdayCount: weekdayCount,
            weekendCount: weekendCount,
            timeOfDayBuckets: timeOfDayBuckets,
            topGenres: topGenres,
            topLanguages: topLanguages,
            companions: companions,
            monthlyBuckets: monthlyBuckets,
            currentStreakWeeks: currentStreak,
            bestStreakWeeks: bestStreak,
            smartInsights: smartInsights,
            totalAllTimeEntries: allEntries.count
        )
    }

    // MARK: - Helpers

    private static func isEntry(_ entry: WatchedEntry, in interval: DateInterval) -> Bool {
        guard let date = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) else { return false }
        return interval.start <= date && date <= interval.end
    }

    private static func computeHeroType(
        count: Int,
        comparison: PeriodComparison,
        timeOfDayBuckets: [KeyCount],
        hasSpendData: Bool,
        totalSpent: Int,
        avgSpent: Int,
        totalAll: Int,
        range: InsightsDateRange
    ) -> HeroInsightType {
        if totalAll < 5 { return .justStarting(count: count) }

        // Volume trend if there's something to compare
        if comparison.previous > 0 || count > 0 {
            if range != .allTime {
                return .volumeTrend(count: count, delta: comparison.delta, period: range.previousPeriodLabel)
            }
        }

        // Time of day dominance (≥40%)
        if let dominant = timeOfDayBuckets.first {
            let total = timeOfDayBuckets.map { $0.count }.reduce(0, +)
            if total > 0 {
                let pct = Int(Double(dominant.count) / Double(total) * 100)
                if pct >= 40 {
                    return .timeOfDay(period: dominant.category, percent: pct, count: dominant.count)
                }
            }
        }

        // Spend data
        if hasSpendData && totalSpent > 0 {
            return .spending(totalCents: totalSpent, avgCents: avgSpent)
        }

        return .volumeTrend(count: count, delta: comparison.delta, period: range.previousPeriodLabel)
    }

    // MARK: - Streak Calculation

    private static func calculateStreaks(from entries: [WatchedEntry]) -> (current: Int, best: Int) {
        let secondsPerWeek: TimeInterval = 7 * 24 * 3600

        var activeWeeks = Set<Int>()
        for entry in entries {
            guard let date = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) else { continue }
            let weekIndex = Int(date.timeIntervalSince1970 / secondsPerWeek)
            activeWeeks.insert(weekIndex)
        }

        guard !activeWeeks.isEmpty else { return (0, 0) }

        let currentWeekIndex = Int(Date().timeIntervalSince1970 / secondsPerWeek)

        // Current streak (allow current week to be grace)
        var startWeek = currentWeekIndex
        if !activeWeeks.contains(startWeek) { startWeek -= 1 }
        var currentStreak = 0
        var checkWeek = startWeek
        while activeWeeks.contains(checkWeek) {
            currentStreak += 1
            checkWeek -= 1
        }

        // Best streak
        let sortedWeeks = activeWeeks.sorted()
        var bestStreak = 0
        var tempStreak = 1
        for i in 1..<sortedWeeks.count {
            if sortedWeeks[i] == sortedWeeks[i - 1] + 1 {
                tempStreak += 1
            } else {
                bestStreak = max(bestStreak, tempStreak)
                tempStreak = 1
            }
        }
        bestStreak = max(bestStreak, tempStreak)

        return (current: currentStreak, best: bestStreak)
    }

    // MARK: - Smart Insights Generation

    private static func generateSmartInsights(
        entries: [WatchedEntry],
        allEntries: [WatchedEntry],
        prevEntries: [WatchedEntry],
        range: InsightsDateRange,
        moviesComparison: PeriodComparison,
        totalWatchTime: Int,
        avgWatchTime: Int,
        totalSpent: Int,
        avgSpent: Int,
        topGenres: [KeyCount],
        timeOfDayBuckets: [KeyCount],
        weekdayCount: Int,
        weekendCount: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> [SmartInsight] {
        let isSmallDataset = allEntries.count < 5
        let prefix = isSmallDataset ? "So far, " : ""
        var insights: [SmartInsight] = []

        // 1. Volume trend
        if !isSmallDataset && range != .allTime && moviesComparison.previous > 0 {
            let direction = moviesComparison.direction
            let pct = abs(Int(moviesComparison.deltaPercent))
            if direction == .up {
                insights.append(SmartInsight(
                    text: "\(prefix)You're watching more movies recently (+\(pct)% vs \(range.previousPeriodLabel)).",
                    icon: "arrow.up.right",
                    detailTitle: "Volume Trend",
                    detailBody: "Compares the number of movies watched in this period versus the same-length prior period."
                ))
            } else if direction == .down && pct > 20 {
                insights.append(SmartInsight(
                    text: "\(prefix)Fewer movies this period (\(pct)% less vs \(range.previousPeriodLabel)).",
                    icon: "arrow.down.right",
                    detailTitle: "Volume Trend",
                    detailBody: "Compares the number of movies watched in this period versus the same-length prior period."
                ))
            }
        }

        // 2. Average movie length
        if avgWatchTime > 0 {
            let hours = avgWatchTime / 60
            let mins = avgWatchTime % 60
            let timeStr = hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
            insights.append(SmartInsight(
                text: "\(prefix)Your average movie length is \(timeStr).",
                icon: "clock",
                detailTitle: "Average Watch Time",
                detailBody: "Total watch time divided by number of movies watched in this period (only movies with duration logged)."
            ))
        }

        // 3. Top genre
        if let topGenre = topGenres.first, entries.count > 0 {
            let total = topGenres.map { $0.count }.reduce(0, +)
            let pct = total > 0 ? Int(Double(topGenre.count) / Double(total) * 100) : 0
            insights.append(SmartInsight(
                text: "\(prefix)\(topGenre.category) is your #1 genre (\(pct)%).",
                icon: "tag",
                detailTitle: "Top Genre",
                detailBody: "Percentage of movies with a genre tag that belong to the most common genre in this period."
            ))
        }

        // 4. Time of day
        if let dominant = timeOfDayBuckets.first {
            let total = timeOfDayBuckets.map { $0.count }.reduce(0, +)
            if total > 0 {
                let pct = Int(Double(dominant.count) / Double(total) * 100)
                if pct >= 40 {
                    insights.append(SmartInsight(
                        text: "\(prefix)You mostly watch at \(dominant.category.lowercased()) (\(pct)% of movies).",
                        icon: "clock.fill",
                        detailTitle: "Preferred Watch Time",
                        detailBody: "Percentage of movies logged with '\(dominant.category)' as the time of day."
                    ))
                }
            }
        }

        // 5. Weekday vs weekend
        let totalDay = weekdayCount + weekendCount
        if totalDay > 0 {
            if weekdayCount > weekendCount {
                let pct = Int(Double(weekdayCount) / Double(totalDay) * 100)
                insights.append(SmartInsight(
                    text: "\(prefix)You watch mostly on weekdays (\(pct)%) — likely after work.",
                    icon: "calendar",
                    detailTitle: "Weekday vs Weekend",
                    detailBody: "Movies watched Monday–Friday vs Saturday–Sunday based on the watched date."
                ))
            } else if weekendCount > weekdayCount {
                let pct = Int(Double(weekendCount) / Double(totalDay) * 100)
                insights.append(SmartInsight(
                    text: "\(prefix)You're a weekend watcher (\(pct)% on weekends).",
                    icon: "calendar",
                    detailTitle: "Weekday vs Weekend",
                    detailBody: "Movies watched Monday–Friday vs Saturday–Sunday based on the watched date."
                ))
            }
        }

        // 6. Spend insight
        if totalSpent > 0 && avgSpent > 0 {
            let totalDollars = Double(totalSpent) / 100.0
            let avgDollars = Double(avgSpent) / 100.0
            insights.append(SmartInsight(
                text: String(format: "\(prefix)You spent $%.0f total, averaging $%.2f per movie.", totalDollars, avgDollars),
                icon: "dollarsign.circle",
                detailTitle: "Spending",
                detailBody: "Total spend and average per movie for all entries with a spend amount logged in this period."
            ))
        }

        // 7. Streak
        if bestStreak >= 2 {
            insights.append(SmartInsight(
                text: "Your best streak was \(bestStreak) \(bestStreak == 1 ? "week" : "weeks") in a row.",
                icon: "flame",
                detailTitle: "Watch Streak",
                detailBody: "A week counts toward your streak if you watched at least one movie in it. Streak is calculated from all-time data."
            ))
        }

        return Array(insights.prefix(6))
    }
}
