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
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Statistics")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToWatchlist"))) { _ in
            // Switch to watchlist tab when notification is tapped
            selectedTab = 1
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}
