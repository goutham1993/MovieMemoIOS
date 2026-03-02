//
//  PremiumPaywallView.swift
//  MovieMemo
//

import SwiftUI
import StoreKit

// MARK: - Main Paywall View

struct PremiumPaywallView: View {

    /// Provide a closure when presenting as a sheet so the X button is shown.
    /// Pass nil when the view fills the Insights tab (user can just tap another tab).
    var onDismiss: (() -> Void)? = nil

    @Environment(SubscriptionManager.self) private var manager

    @State private var selectedID: String = SubscriptionManager.yearlyProductID
    @State private var showError: Bool = false
    @State private var showProductsUnavailable: Bool = false
    @State private var appeared: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                scrollBody

                if showError, let err = manager.purchaseError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Theme.danger.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showProductsUnavailable {
                    Text("Products unavailable. Check your StoreKit configuration.")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Theme.danger.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showError)
            .animation(.easeInOut(duration: 0.3), value: showProductsUnavailable)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if let dismiss = onDismiss {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: dismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.tertiaryText)
                        }
                    }
                }
            }
        }
        .task {
            if manager.products.isEmpty {
                await manager.loadProducts()
            }
        }
        .onChange(of: manager.purchaseError) { _, newValue in
            if newValue != nil {
                showError = true
                Task {
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    showError = false
                }
            }
        }
    }

    // MARK: - Scroll Body

    private var scrollBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroSection
                featureCardsSection
                pricingSection
                ctaSection
                footerSection
            }
        }
        .background(Theme.bg)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Soft radial orb
            RadialGradient(
                colors: [Color.premiumGold.opacity(0.20), Color.clear],
                center: .center,
                startRadius: 10,
                endRadius: 180
            )
            .frame(height: 320)
            .blur(radius: 30)

            VStack(spacing: 0) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .fill(Color.premiumGold.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(Color.premiumGold)
                }

                Text("Unlock Insights")
                    .font(AppFont.hero)
                    .foregroundStyle(.white)
                    .padding(.top, Theme.Spacing.lg)

                Text("See your movie habits come to life.")
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding(.top, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    // MARK: - Feature Cards Section

    private var featureCardsSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            PaywallFeatureCard(
                icon: "chart.bar.fill",
                title: "Your Watching Patterns",
                description: "Discover when and how often you watch movies.",
                chartContent: AnyView(WatchingPatternsChartPreview()),
                accentColor: Color.premiumGold
            )

            PaywallFeatureCard(
                icon: "tag.fill",
                title: "Genre DNA",
                description: "Uncover the genres and languages that define your taste.",
                chartContent: AnyView(GenreDNAChartPreview()),
                accentColor: .white
            )

            PaywallFeatureCard(
                icon: "sparkles",
                title: "Smart Insights",
                description: "Narrative observations about your unique viewing habits.",
                chartContent: AnyView(SmartInsightsPreview()),
                accentColor: Color.premiumGold,
                personalizationNote: "Last month you watched 14 movies."
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.md) {
                PricingCard(
                    product: manager.monthlyProduct,
                    isSelected: selectedID == SubscriptionManager.monthlyProductID,
                    isYearly: false,
                    savingsPercent: nil,
                    fallbackPrice: "$2.99",
                    fallbackSavings: nil,
                    period: "per month"
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedID = SubscriptionManager.monthlyProductID
                    }
                }

                PricingCard(
                    product: manager.yearlyProduct,
                    isSelected: selectedID == SubscriptionManager.yearlyProductID,
                    isYearly: true,
                    savingsPercent: manager.savingsPercent,
                    fallbackPrice: "$19.99",
                    fallbackSavings: 44,
                    period: "per year"
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedID = SubscriptionManager.yearlyProductID
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            if hasIntroOffer {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.footnote)
                    Text("Free trial available — cancel anytime")
                        .font(.footnote)
                }
                .foregroundStyle(Color.premiumGold)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.premiumGold.opacity(0.12), in: Capsule())
            }
        }
        .padding(.top, Theme.Spacing.xl)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        Button {
            isPressed.toggle()
            let product = selectedID == SubscriptionManager.yearlyProductID
                ? manager.yearlyProduct
                : manager.monthlyProduct
            guard let product else {
                showProductsUnavailable = true
                Task {
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    showProductsUnavailable = false
                }
                return
            }
            Task { await manager.purchase(product) }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if manager.isPurchasing {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.85)
                } else {
                    Text("Unlock Premium")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.premiumGold)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(manager.isPurchasing)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.lg)
        .sensoryFeedback(.impact, trigger: isPressed)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            #if targetEnvironment(simulator)
            Button {
                manager.debugTogglePremium()
            } label: {
                Text("⚙️ [Simulator] Toggle Premium")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.yellow.opacity(0.7))
            }
            .padding(.bottom, Theme.Spacing.xs)
            #endif

            Button {
                Task { await manager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Subscriptions renew automatically. Cancel anytime via\nSettings › Apple ID › Subscriptions.")
                .font(AppFont.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            HStack(spacing: Theme.Spacing.xl) {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.top, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Helpers

    private var hasIntroOffer: Bool {
        let product = selectedID == SubscriptionManager.yearlyProductID
            ? manager.yearlyProduct
            : manager.monthlyProduct
        return product?.subscription?.introductoryOffer != nil
    }
}

// MARK: - Feature Card

private struct PaywallFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let chartContent: AnyView
    let accentColor: Color
    var personalizationNote: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 28)

                Text(title)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(.white)
            }

            Text(description)
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            chartContent
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let note = personalizationNote {
                Text(note)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.premiumGold)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product?
    let isSelected: Bool
    let isYearly: Bool
    let savingsPercent: Int?
    let fallbackPrice: String
    let fallbackSavings: Int?
    let period: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Theme.Spacing.sm) {
                Text(product?.displayName ?? (isYearly ? "Yearly" : "Monthly"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)

                Text(product?.displayPrice ?? fallbackPrice)
                    .font(AppFont.price)
                    .foregroundStyle(isSelected ? Color.premiumGold : Theme.primaryText)
                    .contentTransition(.numericText())

                Text(period)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.tertiaryText)

                if isYearly, let pct = savingsPercent ?? fallbackSavings {
                    Text("Save \(pct)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.premiumGold)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.premiumGold.opacity(0.15), in: Capsule())
                } else {
                    Color.clear.frame(height: 22)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isYearly ? 28 : Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(isSelected ? Color.premiumGold.opacity(0.06) : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(
                                isYearly && isSelected ? Color.premiumGold : (isSelected ? Color.premiumGold.opacity(0.4) : Theme.divider),
                                lineWidth: isYearly && isSelected ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(isYearly ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Chart Previews

private struct WatchingPatternsChartPreview: View {
    private let bars: [CGFloat] = [0.4, 0.65, 0.5, 0.85, 0.6, 0.75, 0.45]

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(bars.enumerated()), id: \.offset) { idx, h in
                RoundedRectangle(cornerRadius: 4)
                    .fill(idx == 3 ? Color.premiumGold : Color.premiumGold.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .frame(height: h * 64)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.white.opacity(0.04))
    }
}

private struct GenreDNAChartPreview: View {
    private let genres: [(String, CGFloat)] = [
        ("Drama", 0.85),
        ("Thriller", 0.62),
        ("Comedy", 0.44)
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(genres, id: \.0) { name, fill in
                HStack(spacing: Theme.Spacing.sm) {
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 56, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.55))
                                .frame(width: geo.size.width * fill)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.white.opacity(0.04))
    }
}

private struct SmartInsightsPreview: View {
    private let lines = [
        "You watch most movies on weekends.",
        "Action is your top genre this year."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(Color.premiumGold.opacity(0.7))
                        .frame(width: 5, height: 5)
                        .padding(.top, 5)
                    Text(line)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.white.opacity(0.04))
    }
}

// MARK: - Preview

#Preview("Paywall — not premium") {
    PremiumPaywallView(onDismiss: {})
        .environment(SubscriptionManager())
        .preferredColorScheme(.dark)
}

#Preview("Paywall — in tab (no dismiss)") {
    PremiumPaywallView()
        .environment(SubscriptionManager())
        .preferredColorScheme(.dark)
}
