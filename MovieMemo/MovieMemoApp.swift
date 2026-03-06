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
    @AppStorage("hasCompletedFirstMovieFlow") private var hasCompletedFirstMovieFlow = false
    @Environment(\.modelContext) private var modelContext

    private var shouldShowFirstMovieFlow: Bool {
        hasSeenOnboarding && !hasCompletedFirstMovieFlow
    }

    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                MainTabView()
                    .zIndex(1)
                    .transition(.opacity)
                    .fullScreenCover(isPresented: .init(
                        get: { shouldShowFirstMovieFlow },
                        set: { if !$0 { hasCompletedFirstMovieFlow = true } }
                    )) {
                        FirstMovieFlowView()
                    }
            } else {
                OnboardingCoordinatorView()
                    .zIndex(2)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.5), value: hasSeenOnboarding)
        .onAppear { skipFlowForExistingUsers() }
    }

    /// Existing users who already have movies should never see this flow.
    private func skipFlowForExistingUsers() {
        guard hasSeenOnboarding, !hasCompletedFirstMovieFlow else { return }
        let descriptor = FetchDescriptor<WatchedEntry>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        if count > 0 {
            hasCompletedFirstMovieFlow = true
        }
    }
}
