//
//  MainTabView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var subscriptionManager = SubscriptionManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchedMoviesView()
                .tabItem {
                    Image(systemName: "film")
                    Text("Watched")
                }
                .tag(0)

            WatchlistView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Watchlist")
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Image(systemName: subscriptionManager.isPremium
                          ? "chart.xyaxis.line"
                          : "lock.fill")
                    Text("Insights")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(Theme.accent)
        .environment(subscriptionManager)
        .task {
            await subscriptionManager.loadProducts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToWatchlist"))) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FilterWatchedMovies"))) { _ in
            // Only deep-link into Watched if the user is premium (insights tab is the source)
            selectedTab = 0
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
        .preferredColorScheme(.dark)
}
