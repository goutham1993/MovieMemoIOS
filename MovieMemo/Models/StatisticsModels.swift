//
//  StatisticsModels.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation

struct KeyCount: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

struct KeySum: Identifiable {
    let id = UUID()
    let category: String
    let total: Int
}

struct MonthCount: Identifiable {
    let id = UUID()
    let yearMonth: String // yyyy-MM format
    let count: Int
}

struct StatisticsData {
    let totalMoviesWatched: Int
    let thisMonthMovies: Int
    let totalAmountSpent: Int // in cents
    let thisMonthSpending: Int // in cents
    let averageTheaterSpend: Int // in cents
    let thisMonthAverageTheaterSpend: Int // in cents
    let weekdayCount: Int
    let weekendCount: Int
    let totalWatchTime: Int // in minutes
    let topGenres: [KeyCount]
    let moviesByLocation: [KeyCount]
    let moviesByTimeOfDay: [KeyCount]
    let moviesByLanguage: [KeyCount]
    let moviesByCompanion: [KeyCount]
    let monthlyTrends: [MonthCount]
}

