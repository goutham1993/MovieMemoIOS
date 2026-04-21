//
//  AppStoreConfig.swift
//  MovieMemo
//

import Foundation

enum AppStoreConfig {
    /// Numeric Apple ID from App Store Connect → your app → App Information.
    /// Example: `"6471234567"`. When set, “Write a review” opens the review composer directly.
    static let numericAppID = ""

    private static let fallbackSearchQuery = "MovieMemo Movie Tracker"

    /// Opens the App Store review page when `numericAppID` is set; otherwise App Store search.
    static var writeReviewURL: URL? {
        if !numericAppID.isEmpty {
            return URL(string: "https://apps.apple.com/app/id\(numericAppID)?action=write-review")
        }
        let encoded = fallbackSearchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://apps.apple.com/search?term=\(encoded)")
    }
}
