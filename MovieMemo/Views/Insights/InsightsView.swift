//
//  InsightsView.swift
//  MovieMemo
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: InsightsViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                InsightsContentView(viewModel: vm)
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = InsightsViewModel(repository: MovieRepository(modelContext: modelContext))
            } else {
                viewModel?.invalidateAndReload()
            }
        }
    }
}

// MARK: - Content View (holds the real layout once viewModel is ready)

private struct InsightsContentView: View {
    var viewModel: InsightsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sticky range selector below nav title
                InsightsRangeSelector(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.bar)

                Divider()

                // Main scroll content
                scrollContent
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.invalidateAndReload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        if viewModel.isLoading && viewModel.insightsData == nil {
            loadingView
        } else if let data = viewModel.insightsData {
            if data.moviesCount == 0 && data.totalAllTimeEntries > 0 {
                emptyRangeView(data: data)
            } else if data.totalAllTimeEntries == 0 {
                firstRunView
            } else {
                dataView(data: data)
            }
        } else {
            loadingView
        }
    }

    // MARK: - Data View

    private func dataView(data: InsightsData) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                InsightHeroCard(data: data)

                KPIGrid(data: data)

                TrendsChartCard(data: data)

                // Watching Habits
                HStack {
                    Text("Watching Habits")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 2)
                .padding(.top, 4)

                TimeOfDayDistributionCard(data: data)
                WeekSplitCard(data: data)

                // Taste Profile
                HStack {
                    Text("Taste Profile")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 2)
                .padding(.top, 4)

                TopGenresCard(data: data)
                LanguageInsightsCard(data: data)

                // Context
                ContextGroupCard(data: data)

                // Narrative
                SmartInsightsList(insights: data.smartInsights, dateRange: data.dateRange)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .top) {
            // Loading shimmer while refreshing data that already exists
            if viewModel.isLoading {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 2)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Empty / Loading States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Crunching your data…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func emptyRangeView(data: InsightsData) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 52))
                .foregroundStyle(.quaternary)
            Text("No movies in this period")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Try changing the date range or add a movie.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.selectRange(.allTime)
            } label: {
                Text("View All Time")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var firstRunView: some View {
        VStack(spacing: 20) {
            Image(systemName: "popcorn")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            Text("No movies yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Start logging movies to unlock your personal insights!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}
