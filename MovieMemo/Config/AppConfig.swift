import Foundation

enum AppConfig {
    /// Set via Info.plist (or Xcode build settings) key: `REVENUECAT_API_KEY`
    static var revenueCatAPIKey: String? { string(for: "REVENUECAT_API_KEY") }

    /// Set via Info.plist key: `POSTHOG_API_KEY`
    static var postHogAPIKey: String? { string(for: "POSTHOG_API_KEY") }

    /// Set via Info.plist key: `POSTHOG_HOST` (example: `https://us.i.posthog.com`)
    static var postHogHost: String? { string(for: "POSTHOG_HOST") }

    private static func string(for key: String) -> String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }
}

