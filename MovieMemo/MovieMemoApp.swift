//
//  MovieMemoApp.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData

@main
struct MovieMemoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WatchedEntry.self,
            WatchlistItem.self,
            Genre.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
