//
//  SubscriptionManager.swift
//  MovieMemo
//

import Foundation
import RevenueCat
import Observation

@Observable
@MainActor
final class SubscriptionManager: NSObject {

    // MARK: - Constants

    static let entitlementID     = "premium"
    static let monthlyProductID  = "com.moviememo.premium.monthly"
    static let yearlyProductID   = "com.moviememo.premium.yearly"
    static let lifetimeProductID = "com.moviememo.premium.lifetime"

    // MARK: - State

    private(set) var isPremium:    Bool      = false
    private(set) var packages:     [Package] = []
    private(set) var isPurchasing: Bool      = false
    var purchaseError: String?

    // MARK: - Debug

    #if targetEnvironment(simulator)
    func debugTogglePremium() {
        isPremium.toggle()
    }
    #endif

    // MARK: - Init

    override init() {
        super.init()
        Purchases.shared.delegate = self
    }

    // MARK: - Load Offerings

    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                packages = current.availablePackages
            }
            await checkEntitlements()
        } catch {
            print("[SubscriptionManager] Failed to load offerings: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ package: Package) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        let productID = package.storeProduct.productIdentifier
        let props: [String: Any] = [
            "product_id": productID,
            "price": package.localizedPriceString,
            "plan": planLabel(for: productID)
        ]

        AnalyticsService.shared.track(.purchaseInitiated, properties: props)

        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)

            if userCancelled {
                AnalyticsService.shared.track(.purchaseCancelled, properties: props)
            } else {
                updatePremiumStatus(from: customerInfo)
                if isPremium {
                    AnalyticsService.shared.track(.purchaseCompleted, properties: props)
                }
            }
        } catch {
            purchaseError = error.localizedDescription
            AnalyticsService.shared.track(
                .purchaseFailed,
                properties: props.merging(["error": error.localizedDescription]) { _, new in new }
            )
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        AnalyticsService.shared.track(.restorePurchases)

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updatePremiumStatus(from: customerInfo)
            AnalyticsService.shared.track(.restoreCompleted, properties: ["is_premium": isPremium])
        } catch {
            purchaseError = error.localizedDescription
            AnalyticsService.shared.track(.restoreFailed, properties: ["error": error.localizedDescription])
        }
    }

    // MARK: - Entitlement Check

    func checkEntitlements() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremiumStatus(from: customerInfo)
        } catch {
            print("[SubscriptionManager] Failed to check entitlements: \(error)")
        }
    }

    // MARK: - Computed Helpers

    var monthlyPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == Self.monthlyProductID }
    }

    var yearlyPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == Self.yearlyProductID }
    }

    var lifetimePackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == Self.lifetimeProductID }
    }

    var savingsPercent: Int? {
        guard let monthly = monthlyPackage,
              let yearly  = yearlyPackage else { return nil }
        let annualised = monthly.storeProduct.price * 12
        guard annualised > 0 else { return nil }
        let fraction = (annualised - yearly.storeProduct.price) / annualised
        let pct = Int((NSDecimalNumber(decimal: fraction).doubleValue * 100).rounded())
        return pct > 0 ? pct : nil
    }

    // MARK: - Internal

    func updatePremiumStatus(from customerInfo: CustomerInfo) {
        let active = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        isPremium = active
        AnalyticsService.shared.identify(isPremium: active)
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
}

// MARK: - PurchasesDelegate

extension SubscriptionManager: @preconcurrency PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updatePremiumStatus(from: customerInfo)
    }
}
