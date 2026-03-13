//
//  SubscriptionManager.swift
//  MovieMemo
//

import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class SubscriptionManager {

    // MARK: - Product IDs

    static let monthlyProductID  = "com.moviememo.premium.monthly"
    static let yearlyProductID   = "com.moviememo.premium.yearly"
    static let lifetimeProductID = "com.moviememo.premium.lifetime"

    // MARK: - Published State

    private(set) var isPremium:    Bool      = false
    private(set) var products:     [Product] = []
    private(set) var isPurchasing: Bool      = false
    var purchaseError: String?

    // nonisolated(unsafe) lets deinit cancel the task without actor isolation
    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    // MARK: - Debug

    #if targetEnvironment(simulator)
    /// Instantly grant / revoke premium while running in the simulator.
    /// Never compiled into device builds.
    func debugTogglePremium() {
        isPremium.toggle()
    }
    #endif

    // MARK: - Init / Deinit

    init() {
        updatesTask = Task.detached(priority: .background) { [weak self] in
            for await _ in Transaction.updates {
                await self?.checkEntitlements()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let fetched = try await Product.products(
                for: [Self.monthlyProductID, Self.yearlyProductID, Self.lifetimeProductID]
            )
            let order = [Self.monthlyProductID, Self.yearlyProductID, Self.lifetimeProductID]
            products = fetched.sorted {
                (order.firstIndex(of: $0.id) ?? .max) < (order.firstIndex(of: $1.id) ?? .max)
            }
            await checkEntitlements()
        } catch {
            print("[SubscriptionManager] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        let props: [String: Any] = [
            "product_id": product.id,
            "price": product.displayPrice,
            "plan": planLabel(for: product.id)
        ]

        AnalyticsService.shared.track(.purchaseInitiated, properties: props)

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                do {
                    let transaction = try verify(verification)
                    await transaction.finish()
                    await checkEntitlements()
                    AnalyticsService.shared.track(.purchaseCompleted, properties: props)
                } catch {
                    purchaseError = error.localizedDescription
                    AnalyticsService.shared.track(.purchaseVerifyFailed, properties: props.merging(["error": error.localizedDescription]) { _, new in new })
                }
            case .userCancelled:
                AnalyticsService.shared.track(.purchaseCancelled, properties: props)
            case .pending:
                AnalyticsService.shared.track(.purchasePending, properties: props)
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
            AnalyticsService.shared.track(.purchaseFailed, properties: props.merging(["error": error.localizedDescription]) { _, new in new })
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        AnalyticsService.shared.track(.restorePurchases)

        do {
            try await AppStore.sync()
            await checkEntitlements()
            AnalyticsService.shared.track(.restoreCompleted, properties: ["is_premium": isPremium])
        } catch {
            purchaseError = error.localizedDescription
            AnalyticsService.shared.track(.restoreFailed, properties: ["error": error.localizedDescription])
        }
    }

    // MARK: - Entitlement Check

    func checkEntitlements() async {
        var hasPremium = false
        for id in [Self.monthlyProductID, Self.yearlyProductID, Self.lifetimeProductID] {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified = result {
                hasPremium = true
                break
            }
        }
        isPremium = hasPremium
        AnalyticsService.shared.identify(isPremium: hasPremium)
    }

    // MARK: - Computed Helpers

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    /// Approximate whole-number percentage saved by choosing yearly over 12× monthly.
    var savingsPercent: Int? {
        guard let monthly = monthlyProduct,
              let yearly  = yearlyProduct else { return nil }
        let annualised = monthly.price * 12
        guard annualised > 0 else { return nil }
        let fraction = (annualised - yearly.price) / annualised
        // Decimal doesn't conform to FloatingPoint, so convert to Double before rounding.
        let pct = Int((NSDecimalNumber(decimal: fraction).doubleValue * 100).rounded())
        return pct > 0 ? pct : nil
    }

    // MARK: - Private

    private func planLabel(for productID: String) -> String {
        switch productID {
        case Self.monthlyProductID:  return "monthly"
        case Self.yearlyProductID:   return "yearly"
        case Self.lifetimeProductID: return "lifetime"
        default:                     return "unknown"
        }
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified:          throw SubscriptionManagerError.failedVerification
        }
    }
}

enum SubscriptionManagerError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "Purchase could not be verified. Please try again."
    }
}
