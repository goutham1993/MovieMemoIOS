//
//  AnalyticsService.swift
//  MovieMemo
//

import UIKit
import PostHog

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    func track(_ event: Event, properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event.rawValue, properties: properties.isEmpty ? nil : properties)
    }

    func identify(isPremium: Bool) {
        let props: [String: Any] = ["is_premium": isPremium]
        PostHogSDK.shared.identify(UIDevice.current.identifierForVendor?.uuidString ?? "anonymous", userProperties: props)
    }

    enum Event: String {
        case appOpened               = "app_opened"
        case onboardingCompleted     = "onboarding_completed"
        case movieAdded              = "movie_added"
        case movieEdited             = "movie_edited"
        case movieDeleted            = "movie_deleted"
        case searchUsed              = "search_used"
        case filterApplied           = "filter_applied"
        case sortChanged             = "sort_changed"
        case watchlistItemAdded      = "watchlist_item_added"
        case watchlistItemDeleted    = "watchlist_item_deleted"
        case watchlistMovedToWatched = "watchlist_item_moved_to_watched"
        case tabViewed               = "tab_viewed"
        case insightsViewed          = "insights_viewed"
        case statisticsViewed        = "statistics_viewed"
        case paywallViewed           = "paywall_viewed"
        case unlockPremiumTapped     = "unlock_premium_tapped"
        case purchaseInitiated       = "purchase_initiated"
        case purchaseCompleted       = "purchase_completed"
        case purchaseFailed          = "purchase_failed"
        case restorePurchases        = "restore_purchases_initiated"
        case dataExported            = "data_exported"
        case dataImported            = "data_imported"
        case dataImportFailed        = "data_import_failed"
        case clearedWatchedMovies    = "cleared_watched_movies"
        case clearedWatchlistItems   = "cleared_watchlist_items"
        case upgradeTappedSettings   = "upgrade_tapped_settings"
        case rateAppTapped           = "rate_app_tapped"
    }
}

