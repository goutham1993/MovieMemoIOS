import Combine
import StoreKit
import SwiftUI
import UIKit

// MARK: - Review prompt sheets (before StoreKit)

enum ReviewPromptSheet: String, Identifiable, Equatable {
    case satisfaction
    case feedback
    var id: String { rawValue }
}

@MainActor
final class ReviewManager: ObservableObject {

    static let shared = ReviewManager()
    private init() {}

    private let milestones: Set<Int> = [5, 10, 25]
    private let minimumDaysBetweenRequests = 60
    private let bannerAutoDismissSeconds: Double = 10

    private enum Keys {
        static let totalMoviesLogged = "ReviewManager.totalMoviesLogged"
        static let lastReviewRequestDate = "ReviewManager.lastReviewRequestDate"
        static let lastPromptedMilestone = "ReviewManager.lastPromptedMilestone"
    }

    private var totalMoviesLogged: Int {
        get { UserDefaults.standard.integer(forKey: Keys.totalMoviesLogged) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.totalMoviesLogged) }
    }

    private var lastReviewRequestDate: Date? {
        get {
            let interval = UserDefaults.standard.double(forKey: Keys.lastReviewRequestDate)
            return interval == 0 ? nil : Date(timeIntervalSince1970: interval)
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0,
                                      forKey: Keys.lastReviewRequestDate)
        }
    }

    private var lastPromptedMilestone: Int {
        get { UserDefaults.standard.integer(forKey: Keys.lastPromptedMilestone) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastPromptedMilestone) }
    }

    // Legacy sheet flow (kept for possible future reuse)
    @Published private(set) var activeSheet: ReviewPromptSheet?

    // New non-blocking banner prompt
    @Published private(set) var isBannerVisible: Bool = false

    var activeSheetBinding: Binding<ReviewPromptSheet?> {
        Binding(
            get: { self.activeSheet },
            set: { self.activeSheet = $0 }
        )
    }

    func recordMovieLogged() {
        totalMoviesLogged += 1
        requestIfAppropriate()
    }

    /// Settings — goes straight to Apple’s review prompt (no satisfaction sheet).
    func requestReviewDirectly() {
        Task {
            performStoreReview()
            lastReviewRequestDate = Date()
        }
    }

    /// In-app star prompt only (Apple does not offer written review in this dialog).
    func requestInAppStarRating() {
        activeSheet = nil
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            performStoreReview()
        }
    }

    func userTappedRateFromBanner() {
        dismissBanner()
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            performStoreReview()
        }
    }

    func dismissBanner() {
        isBannerVisible = false
    }

    func dismissSatisfactionPrompt() {
        activeSheet = nil
    }

    func userTappedNotReally() {
        activeSheet = .feedback
    }

    func feedbackDone() {
        activeSheet = nil
    }

    private func requestIfAppropriate() {
        let nextMilestone = milestones
            .sorted()
            .first(where: { totalMoviesLogged >= $0 && $0 > lastPromptedMilestone })

        guard let milestone = nextMilestone else { return }

        if let lastDate = lastReviewRequestDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSince >= minimumDaysBetweenRequests else { return }
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isBannerVisible = true
            lastReviewRequestDate = Date()
            lastPromptedMilestone = milestone

            // Auto-dismiss so it doesn’t linger forever.
            Task {
                try? await Task.sleep(nanoseconds: UInt64(bannerAutoDismissSeconds * 1_000_000_000))
                self.isBannerVisible = false
            }
        }
    }

    private func performStoreReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
