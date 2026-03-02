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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
            AppRootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - App Root Gate

/// Reads `hasSeenOnboarding` and routes to either the onboarding flow or the main app.
/// Fades between the two with a smooth easeOut transition.
private struct AppRootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                MainTabView()
                    .zIndex(1)
                    .transition(.opacity)
            } else {
                OnboardingCoordinatorView()
                    .zIndex(2)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.5), value: hasSeenOnboarding)
    }
}
