//
//  SubscriptionManager.swift
//  MovieMemo
//

import Foundation
import StoreKit
import Observation
import RevenueCat

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

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verify(verification)
                await transaction.finish()
                await checkEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Entitlement Check

    func checkEntitlements() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements.all["MovieMemo Pro"]?.isActive == true
        } catch {
            print("[SubscriptionManager] Failed to check entitlements: \(error)")
        }
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
