//
//  OnboardingCoordinatorView.swift
//  MovieMemo
//

import SwiftUI

// MARK: - Coordinator

/// Entry gate for the onboarding flow.
/// Manages page state, advances via Continue/Start, and marks onboarding complete via `hasSeenOnboarding`.
struct OnboardingCoordinatorView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let totalPages = 5

    var body: some View {
        ZStack {
            CinematicBackgroundView()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1(isActive: currentPage == 0).tag(0)
                    OnboardingPage2(isActive: currentPage == 1).tag(1)
                    OnboardingPage3(isActive: currentPage == 2).tag(2)
                    OnboardingPage4(isActive: currentPage == 3).tag(3)
                    OnboardingPage5(isActive: currentPage == 4).tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                OnboardingControlsView(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    onPrimary: advance,
                    onSecondary: complete
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions

    private func advance() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        } else {
            complete()
        }
    }

    private func complete() {
        hasSeenOnboarding = true
    }
}

// MARK: - Page 1: Entry (Brand)

private struct OnboardingPage1: View {
    let isActive: Bool

    var body: some View {
        OnboardingPageView(
            title: "MovieMemo",
            subtitle: "Remember every film that mattered.",
            icon: "sparkles.tv",
            iconSize: 72,
            isActive: isActive
        ) {
            EmptyView()
        }
    }
}

// MARK: - Page 2: Track

private struct OnboardingPage2: View {
    let isActive: Bool

    var body: some View {
        OnboardingPageView(
            title: "Track what you watch.",
            subtitle: "Build your personal movie history in seconds.",
            isActive: isActive
        ) {
            MockAddMovieCardView()
                .padding(.bottom, Theme.Spacing.md)
        }
    }
}

// MARK: - Page 3: Patterns

private struct OnboardingPage3: View {
    let isActive: Bool

    var body: some View {
        OnboardingPageView(
            title: "Discover your habits.",
            subtitle: "See when, what, and how you watch.",
            isActive: isActive
        ) {
            MockChartPreviewView()
                .padding(.bottom, Theme.Spacing.md)
        }
    }
}

// MARK: - Page 4: Insights

private struct OnboardingPage4: View {
    let isActive: Bool

    var body: some View {
        OnboardingPageView(
            title: "Understand your taste.",
            subtitle: "Your cinema DNA, beautifully revealed.",
            isActive: isActive
        ) {
            InsightPreviewCardView()
                .padding(.bottom, Theme.Spacing.md)
        }
    }
}

// MARK: - Page 5: Premium Hint (soft)

private struct OnboardingPage5: View {
    let isActive: Bool

    var body: some View {
        OnboardingPageView(
            title: "Unlock deeper insights.",
            subtitle: "Go beyond tracking. See the full picture.",
            isActive: isActive
        ) {
            PremiumHintPreviewView()
                .padding(.bottom, Theme.Spacing.md)
        }
    }
}

// MARK: - Mock Add Movie Card (Page 2)

private struct MockAddMovieCardView: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {

            // Poster placeholder
            RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                .fill(Theme.surface2)
                .frame(width: 52, height: 76)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundColor(Theme.tertiaryText)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Interstellar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                Text("Christopher Nolan · 2014")
                    .font(AppFont.caption)
                    .foregroundColor(Theme.secondaryText)

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < 4 ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(i < 4 ? Color.premiumGold : Theme.tertiaryText)
                    }
                }

                Text("Watched yesterday")
                    .font(AppFont.caption)
                    .foregroundColor(Theme.tertiaryText)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.divider, lineWidth: 1)
        )
        .padding(.horizontal, Theme.Spacing.xl)
    }
}
