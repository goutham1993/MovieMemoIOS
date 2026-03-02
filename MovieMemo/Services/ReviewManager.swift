import StoreKit
import UIKit

@MainActor
final class ReviewManager {

    static let shared = ReviewManager()
    private init() {}

    private let milestones: Set<Int> = [5, 10, 25]
    private let minimumDaysBetweenRequests = 60

    private enum Keys {
        static let totalMoviesLogged = "ReviewManager.totalMoviesLogged"
        static let lastReviewRequestDate = "ReviewManager.lastReviewRequestDate"
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

    func recordMovieLogged() {
        totalMoviesLogged += 1
        requestIfAppropriate()
    }

    /// Called from Settings — bypasses milestone/cooldown gate since the user explicitly asked.
    func requestReviewDirectly() {
        Task {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            SKStoreReviewController.requestReview(in: scene)
            lastReviewRequestDate = Date()
        }
    }

    private func requestIfAppropriate() {
        guard milestones.contains(totalMoviesLogged) else { return }

        if let lastDate = lastReviewRequestDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSince >= minimumDaysBetweenRequests else { return }
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            SKStoreReviewController.requestReview(in: scene)
            lastReviewRequestDate = Date()
        }
    }
}
