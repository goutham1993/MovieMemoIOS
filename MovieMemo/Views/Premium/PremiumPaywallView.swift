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
    @State private var heroUnlocked = false
    @State private var showError    = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                scrollBody

                // Error toast
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
            }
            .animation(.easeInOut(duration: 0.3), value: showError)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "1E0B3A"), for: .navigationBar)
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
                featuresSection
                pricingSection
                footerSection
            }
        }
        .background(Theme.bg)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1E0B3A"), Color(hex: "0A1628"), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 16) {
                // Animated icon — lock transitions into the Insights chart icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.35), Theme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)

                    Image(systemName: heroUnlocked ? "chart.xyaxis.line" : "lock.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .contentTransition(.symbolEffect(.replace))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                            heroUnlocked = true
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text("Unlock Insights")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Your personal cinema analytics — patterns,\nhabits and trends, beautifully visualised.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 28)
                }
            }
            .padding(.top, 36)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 0) {
            PaywallSectionDivider(title: "What You'll Unlock")
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                PaywallFeatureRow(
                    icon: "chart.bar.fill",
                    iconColor: Color(hex: "4A90E2"),
                    title: "Viewing Trends",
                    description: "See how your watching evolves month by month with beautiful bar charts.",
                    preview: AnyView(MiniBarChartPreview(color: Color(hex: "4A90E2")))
                )
                PaywallFeatureRow(
                    icon: "tag.fill",
                    iconColor: Color(hex: "AF52DE"),
                    title: "Genre & Language DNA",
                    description: "Discover your top genres and the languages you watch most.",
                    preview: AnyView(MiniProgressBarPreview(color: Color(hex: "AF52DE")))
                )
                PaywallFeatureRow(
                    icon: "clock.fill",
                    iconColor: Theme.accent,
                    title: "Time & Day Patterns",
                    description: "Find out whether you're a morning, evening, or weekend watcher.",
                    preview: AnyView(MiniTimePatternPreview())
                )
                PaywallFeatureRow(
                    icon: "indianrupeesign.circle.fill",
                    iconColor: Color(hex: "30D158"),
                    title: "Spending Analytics",
                    description: "Track your theater spending over time and spot seasonal trends.",
                    preview: AnyView(MiniBarChartPreview(color: Color(hex: "30D158")))
                )
                PaywallFeatureRow(
                    icon: "flame.fill",
                    iconColor: Color(hex: "FF6B35"),
                    title: "Watch Streaks",
                    description: "Build consecutive weekly watching streaks and celebrate milestones.",
                    preview: AnyView(MiniStreakPreview())
                )
                PaywallFeatureRow(
                    icon: "sparkles",
                    iconColor: Color(hex: "FFD700"),
                    title: "Smart Personalized Insights",
                    description: "Get AI-crafted narrative observations about your unique viewing habits.",
                    preview: AnyView(MiniSmartInsightsPreview()),
                    isLast: true
                )
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.surface)
                    .fill(Theme.surface)
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 16) {
            PaywallSectionDivider(title: "Choose Your Plan")

            HStack(spacing: 12) {
                PricingCard(
                    product: manager.monthlyProduct,
                    isSelected: selectedID == SubscriptionManager.monthlyProductID,
                    isMostPopular: false,
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
                    isMostPopular: true,
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
            .padding(.horizontal, 16)

            // Primary CTA
            Button {
                Task {
                    let product = selectedID == SubscriptionManager.yearlyProductID
                        ? manager.yearlyProduct
                        : manager.monthlyProduct
                    if let product {
                        await manager.purchase(product)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if manager.isPurchasing {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("Get MovieMemo Premium")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Theme.accent)
                )
                .foregroundStyle(.black)
            }
            .disabled(manager.isPurchasing)
            .padding(.horizontal, 16)

            // Introductory offer badge (shown only when trial is available)
            if hasIntroOffer {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.footnote)
                    Text("Free trial available — cancel anytime")
                        .font(.footnote)
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.accent.opacity(0.12), in: Capsule())
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await manager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .underline()
            }

            Text("Subscriptions renew automatically. Cancel anytime via\nSettings › Apple ID › Subscriptions.")
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 20) {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryText)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryText)
            }
        }
        .padding(.vertical, 28)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private var hasIntroOffer: Bool {
        let product = selectedID == SubscriptionManager.yearlyProductID
            ? manager.yearlyProduct
            : manager.monthlyProduct
        return product?.subscription?.introductoryOffer != nil
    }
}

// MARK: - Section Divider

private struct PaywallSectionDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Theme.divider)
                .frame(height: 1)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.tertiaryText)
                .fixedSize()
                .padding(.horizontal, 12)

            Rectangle()
                .fill(Theme.divider)
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }
}

// MARK: - Feature Row

private struct PaywallFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let preview: AnyView
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.icon)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                }

                // Copy
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                // Mini preview
                preview
                    .frame(width: 58, height: 38)
                    .clipped()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)

            if !isLast {
                Rectangle()
                    .fill(Theme.divider)
                    .frame(height: 1)
                    .padding(.leading, 74)
            }
        }
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product?
    let isSelected: Bool
    let isMostPopular: Bool
    let savingsPercent: Int?
    let fallbackPrice: String
    let fallbackSavings: Int?
    let period: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // "Most Popular" or spacer to align cards
                if isMostPopular {
                    Text("MOST POPULAR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accent, in: Capsule())
                } else {
                    Color.clear.frame(height: 20)
                }

                Text(product?.displayName ?? (isMostPopular ? "Yearly" : "Monthly"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)

                // Show fallback price immediately; updates to live StoreKit price when available
                Text(product?.displayPrice ?? fallbackPrice)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.primaryText)
                    .contentTransition(.numericText())

                Text(period)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.tertiaryText)

                // Savings badge for yearly / spacer for monthly
                if isMostPopular, let pct = savingsPercent ?? fallbackSavings {
                    Text("Save \(pct)%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accent.opacity(0.15), in: Capsule())
                } else {
                    Color.clear.frame(height: 20)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Theme.accent.opacity(0.08) : Theme.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Theme.accent : Theme.divider,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Preview: Bar Chart

private struct MiniBarChartPreview: View {
    let color: Color
    // Heights normalised 0–1; index 3 is the peak bar
    private let barHeights: [CGFloat] = [0.45, 0.7, 0.55, 0.9, 0.62, 0.8]

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { idx, h in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(idx == 3 ? 1.0 : 0.4))
                    .frame(width: 6, height: h * 34)
            }
        }
    }
}

// MARK: - Mini Preview: Progress Bars (Genre/Language)

private struct MiniProgressBarPreview: View {
    let color: Color
    private let fills: [CGFloat] = [0.85, 0.6, 0.38]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(fills.enumerated()), id: \.offset) { idx, fill in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.surface2)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.5 + (0.5 * (1 - CGFloat(idx) * 0.25))))
                        .frame(width: fill * 50, height: 5)
                }
            }
        }
        .frame(width: 54)
    }
}

// MARK: - Mini Preview: Time-of-Day Pattern

private struct MiniTimePatternPreview: View {
    // Evening (index 2) is the highlighted slot
    private let labels = ["M", "A", "E", "N"]
    private let highlighted = 2

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(labels.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i == highlighted ? Theme.accent : Theme.surface2)
                        .frame(width: 11, height: 18)
                }
            }
            HStack(spacing: 4) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(Theme.tertiaryText)
                        .frame(width: 11)
                }
            }
        }
    }
}

// MARK: - Mini Preview: Streak Badge

private struct MiniStreakPreview: View {
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "FF6B35"))
            Text("7 wks")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.primaryText)
        }
    }
}

// MARK: - Mini Preview: Smart Insights Bullets

private struct MiniSmartInsightsPreview: View {
    private let lines = ["Weekends are peak", "Action is your top"]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(lines, id: \.self) { line in
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "FFD700").opacity(0.85))
                        .frame(width: 4, height: 4)
                    Text(line)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
            }
        }
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
