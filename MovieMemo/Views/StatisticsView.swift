//
//  StatisticsView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StatisticsViewModel?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel?.isLoading == true {
                    VStack {
                        ProgressView()
                        Text("Loading statistics...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let data = viewModel?.statisticsData {
                    LazyVStack(spacing: 20) {
                        // Overview Cards
                        OverviewCardsView(data: data)
                        
                        // Charts and Lists
                        ChartsSectionView(data: data)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No data available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Watch some movies to see your statistics!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel?.refreshStatistics()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StatisticsViewModel(repository: MovieRepository(modelContext: modelContext))
            }
        }
    }
}

struct OverviewCardsView: View {
    let data: StatisticsData
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Movies",
                    value: "\(data.totalMoviesWatched)",
                    subtitle: "This month: \(data.thisMonthMovies)",
                    icon: "film",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Spent",
                    value: formatCurrency(data.totalAmountSpent),
                    subtitle: "This month: \(formatCurrency(data.thisMonthSpending))",
                    icon: "dollarsign.circle",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Avg Theater Spend",
                    value: formatCurrency(data.averageTheaterSpend),
                    subtitle: "This month: \(formatCurrency(data.thisMonthAverageTheaterSpend))",
                    icon: "theatermasks",
                    color: .orange
                )
                
                StatCard(
                    title: "Watch Time",
                    value: formatDuration(data.totalWatchTime),
                    subtitle: "Weekday: \(data.weekdayCount) | Weekend: \(data.weekendCount)",
                    icon: "clock",
                    color: .purple
                )
            }
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let days = hours / 24
        let remainingHours = hours % 24
        
        if days > 0 {
            return "\(days)d \(remainingHours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ChartsSectionView: View {
    let data: StatisticsData
    
    var body: some View {
        VStack(spacing: 20) {
            // Top Genres
            if !data.topGenres.isEmpty {
                ChartSectionView(
                    title: "Top Genres",
                    items: data.topGenres.map { "\($0.category) (\($0.count))" },
                    icon: "tag"
                )
            }
            
            // Movies by Location
            if !data.moviesByLocation.isEmpty {
                ChartSectionView(
                    title: "Movies by Location",
                    items: data.moviesByLocation.map { "\($0.category) (\($0.count))" },
                    icon: "location"
                )
            }
            
            // Movies by Time of Day
            if !data.moviesByTimeOfDay.isEmpty {
                ChartSectionView(
                    title: "Movies by Time of Day",
                    items: data.moviesByTimeOfDay.map { "\($0.category) (\($0.count))" },
                    icon: "clock"
                )
            }
            
            // Movies by Language
            if !data.moviesByLanguage.isEmpty {
                ChartSectionView(
                    title: "Movies by Language",
                    items: data.moviesByLanguage.map { "\($0.category) (\($0.count))" },
                    icon: "globe"
                )
            }
            
            // Movies by Companion
            if !data.moviesByCompanion.isEmpty {
                ChartSectionView(
                    title: "Movies by Companion",
                    items: data.moviesByCompanion.map { "\($0.category) (\($0.count))" },
                    icon: "person.2"
                )
            }
            
            // Monthly Trends
            if !data.monthlyTrends.isEmpty {
                MonthlyTrendsView(trends: data.monthlyTrends)
            }
        }
    }
}

struct ChartSectionView: View {
    let title: String
    let items: [String]
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MonthlyTrendsView: View {
    let trends: [MonthCount]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Monthly Trends")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(trends) { trend in
                    HStack {
                        Text(trend.yearMonth)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(trend.count) movies")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}

