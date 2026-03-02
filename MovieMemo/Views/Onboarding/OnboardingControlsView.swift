//
//  OnboardingControlsView.swift
//  MovieMemo
//

import SwiftUI

/// Fixed-bottom onboarding controls: capsule page indicator + gold CTA + secondary text action.
struct OnboardingControlsView: View {
    let currentPage: Int
    let totalPages: Int
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    private var primaryLabel: String {
        currentPage == totalPages - 1 ? "Start" : "Continue"
    }

    private var secondaryLabel: String {
        currentPage == totalPages - 1 ? "I'll explore first" : "Skip"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {

            // Minimalist capsule page indicator
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == currentPage
                                ? Color.premiumGold.opacity(0.9)
                                : Color.white.opacity(0.2)
                        )
                        .frame(
                            width: index == currentPage ? 20 : 6,
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.25), value: currentPage)
                }
            }
            .padding(.bottom, Theme.Spacing.xs)

            PrimaryGoldButton(label: primaryLabel, action: onPrimary)

            Button(action: onSecondary) {
                Text(secondaryLabel)
                    .font(AppFont.body)
                    .foregroundColor(Theme.secondaryText)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [.clear, Color(hex: "080818").opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}
