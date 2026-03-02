//
//  OnboardingPageView.swift
//  MovieMemo
//

import SwiftUI

/// Generic onboarding page container.
/// Animates icon → content → title → subtitle with staggered fade-up on becoming active.
/// Resets instantly when page becomes inactive (no exit animation).
struct OnboardingPageView<Content: View>: View {
    let title: String
    let subtitle: String
    var icon: String? = nil
    var iconSize: CGFloat = 64
    var isActive: Bool
    @ViewBuilder let content: () -> Content

    @State private var iconVisible     = false
    @State private var contentVisible  = false
    @State private var titleVisible    = false
    @State private var subtitleVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Optional hero icon (Page 1)
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .thin))
                    .foregroundColor(Color.premiumGold)
                    .padding(.bottom, Theme.Spacing.xl)
                    .opacity(iconVisible ? 1 : 0)
                    .offset(y: iconVisible ? 0 : 10)
            }

            // Custom visual content (cards, charts, etc.)
            content()
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 10)

            // Text block
            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(AppFont.hero)
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 10)

                Text(subtitle)
                    .font(AppFont.body)
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .opacity(subtitleVisible ? 1 : 0)
                    .offset(y: subtitleVisible ? 0 : 10)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.lg)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue { animateIn() } else { resetAll() }
        }
        .onAppear {
            if isActive { animateIn() }
        }
    }

    // MARK: - Animation

    private func animateIn() {
        resetAll()
        // Brief delay lets TabView's page slide finish before content appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.45))              { iconVisible    = true }
            withAnimation(.easeOut(duration: 0.45).delay(0.10)) { contentVisible  = true }
            withAnimation(.easeOut(duration: 0.45).delay(0.18)) { titleVisible    = true }
            withAnimation(.easeOut(duration: 0.45).delay(0.26)) { subtitleVisible = true }
        }
    }

    private func resetAll() {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            iconVisible     = false
            contentVisible  = false
            titleVisible    = false
            subtitleVisible = false
        }
    }
}
