//
//  MovieMemoApp.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData
import StoreKit
import RevenueCat

@main
struct MovieMemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        Purchases.configure(withAPIKey: "appl_dFQpktgFJDJEkQhIVBNREFSeFlD")

        #if DEBUG
        Task {
            let ids = [
                SubscriptionManager.monthlyProductID,
                SubscriptionManager.yearlyProductID,
                SubscriptionManager.lifetimeProductID
            ]
            let products = try? await Product.products(for: ids)
            print(
                "[StoreKit] direct fetch count: \(products?.count ?? -1), ids: \(products?.map(\.id) ?? [])"
            )
        }
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WatchedEntry.self,
            WatchlistItem.self,
            Genre.self
        ])
        // Note: This project's SwiftData SDK doesn't expose a `url:` initializer for ModelConfiguration.
        // We still name the configuration to make the store stable and resettable in DEBUG.
        let modelConfiguration = ModelConfiguration(
            "MovieMemo",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            #if DEBUG
            // SwiftData can fail to load when the on-device store is incompatible with the current schema.
            // In DEBUG we reset the local store to unblock development.
            do {
                // Best-effort purge: SwiftData's underlying SQLite location is not configurable here,
                // so we remove any likely store files in Application Support.
                let appSupport = URL.applicationSupportDirectory
                let candidates = [
                    appSupport.appending(path: "MovieMemo").appendingPathExtension("sqlite"),
                    appSupport.appending(path: "MovieMemo").appendingPathExtension("store"),
                    appSupport.appending(path: "default").appendingPathExtension("sqlite"),
                    appSupport.appending(path: "default").appendingPathExtension("store")
                ]
                for base in candidates {
                    let sidecars = [
                        base,
                        base.appendingPathExtension("sqlite-wal"),
                        base.appendingPathExtension("sqlite-shm"),
                        base.appendingPathExtension("store-wal"),
                        base.appendingPathExtension("store-shm")
                    ]
                    for url in sidecars where FileManager.default.fileExists(atPath: url.path) {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer (even after DEBUG reset): \(error)")
            }
            #else
            fatalError("Could not create ModelContainer: \(error)")
            #endif
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
