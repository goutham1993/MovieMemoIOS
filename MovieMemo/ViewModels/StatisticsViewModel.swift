//
//  StatisticsViewModel.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var statisticsData: StatisticsData?
    @Published var isLoading = false
    
    private let repository: MovieRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: MovieRepository) {
        self.repository = repository
        loadStatistics()
    }
    
    func loadStatistics() {
        print("ViewModel: Starting loadStatistics")
        isLoading = true
        
        // Get data on main thread since ModelContext is not thread-safe
        let watchedEntries = repository.getAllWatchedEntries()
        print("ViewModel: Got \(watchedEntries.count) entries from repository")
        
        // Do heavy calculations on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { 
                print("ViewModel: Self is nil in background thread")
                return 
            }
            
            print("ViewModel: Starting calculations on background thread")
            let statistics = self.calculateStatistics(from: watchedEntries)
            print("ViewModel: Calculations completed")
            
            DispatchQueue.main.async {
                print("ViewModel: Updating UI on main thread")
                self.statisticsData = statistics
                self.isLoading = false
                print("ViewModel: UI updated - isLoading: \(self.isLoading), hasData: \(self.statisticsData != nil)")
            }
        }
    }
    
    private func calculateStatistics(from entries: [WatchedEntry]) -> StatisticsData {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        // Basic counts
        let totalMoviesWatched = entries.count
        let thisMonthMovies = entries.filter { entry in
            let entryDate = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) ?? Date.distantPast
            let entryMonth = calendar.component(.month, from: entryDate)
            let entryYear = calendar.component(.year, from: entryDate)
            return entryMonth == currentMonth && entryYear == currentYear
        }.count
        
        // Financial data
        let totalAmountSpent = entries.compactMap { $0.spendCents }.reduce(0, +)
        let thisMonthSpending = entries.filter { entry in
            let entryDate = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) ?? Date.distantPast
            let entryMonth = calendar.component(.month, from: entryDate)
            let entryYear = calendar.component(.year, from: entryDate)
            return entryMonth == currentMonth && entryYear == currentYear
        }.compactMap { $0.spendCents }.reduce(0, +)
        
        let theaterEntries = entries.filter { $0.locationTypeEnum == .theater }
        let averageTheaterSpend = theaterEntries.isEmpty ? 0 : 
            theaterEntries.compactMap { $0.spendCents }.reduce(0, +) / theaterEntries.count
        
        let thisMonthTheaterEntries = theaterEntries.filter { entry in
            let entryDate = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) ?? Date.distantPast
            let entryMonth = calendar.component(.month, from: entryDate)
            let entryYear = calendar.component(.year, from: entryDate)
            return entryMonth == currentMonth && entryYear == currentYear
        }
        let thisMonthAverageTheaterSpend = thisMonthTheaterEntries.isEmpty ? 0 :
            thisMonthTheaterEntries.compactMap { $0.spendCents }.reduce(0, +) / thisMonthTheaterEntries.count
        
        // Weekday vs Weekend
        let weekdayCount = entries.filter { entry in
            guard let entryDate = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) else { return false }
            let weekday = calendar.component(.weekday, from: entryDate)
            return weekday >= 2 && weekday <= 6 // Monday to Friday
        }.count
        let weekendCount = totalMoviesWatched - weekdayCount
        
        // Total watch time
        let totalWatchTime = entries.compactMap { $0.durationMin }.reduce(0, +)
        
        // Top genres
        let genreCounts = Dictionary(grouping: entries.compactMap { $0.genre }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { KeyCount(category: $0.key, count: $0.value) }
        
        // Movies by location
        let locationCounts = Dictionary(grouping: entries, by: { $0.locationTypeEnum.displayName })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .map { KeyCount(category: $0.key, count: $0.value) }
        
        // Movies by time of day
        let timeOfDayCounts = Dictionary(grouping: entries, by: { $0.timeOfDayEnum.displayName })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .map { KeyCount(category: $0.key, count: $0.value) }
        
        // Movies by language
        let languageCounts = Dictionary(grouping: entries, by: { $0.languageEnum.displayName })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .map { KeyCount(category: $0.key, count: $0.value) }
        
        // Movies by companion
        let companionCounts = Dictionary(grouping: entries.compactMap { $0.companions?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) }, by: { $0 ?? "Solo" })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .map { KeyCount(category: $0.key, count: $0.value) }
        
        // Monthly trends
        let monthlyCounts = Dictionary(grouping: entries, by: { entry in
            guard let entryDate = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) else { return "Unknown" }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: entryDate)
        })
        .mapValues { $0.count }
        .sorted { $0.key < $1.key }
        .map { MonthCount(yearMonth: $0.key, count: $0.value) }
        
        return StatisticsData(
            totalMoviesWatched: totalMoviesWatched,
            thisMonthMovies: thisMonthMovies,
            totalAmountSpent: totalAmountSpent,
            thisMonthSpending: thisMonthSpending,
            averageTheaterSpend: averageTheaterSpend,
            thisMonthAverageTheaterSpend: thisMonthAverageTheaterSpend,
            weekdayCount: weekdayCount,
            weekendCount: weekendCount,
            totalWatchTime: totalWatchTime,
            topGenres: Array(genreCounts),
            moviesByLocation: Array(locationCounts),
            moviesByTimeOfDay: Array(timeOfDayCounts),
            moviesByLanguage: Array(languageCounts),
            moviesByCompanion: Array(companionCounts),
            monthlyTrends: Array(monthlyCounts)
        )
    }
    
    func refreshStatistics() {
        loadStatistics()
    }
}

