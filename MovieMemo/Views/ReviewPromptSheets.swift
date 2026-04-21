//
//  ReviewPromptSheets.swift
//  MovieMemo
//

import SwiftUI

private enum ReviewFeedbackConfig {
    /// Replace with your support inbox before shipping.
    static let feedbackEmail = "support@example.com"
}

/// Root-level sheets: satisfaction gate → optional improvement (no StoreKit on negative path).
struct ReviewPromptSheetHost: View {
    @ObservedObject private var reviewManager = ReviewManager.shared
    @State private var feedbackText = ""

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .sheet(item: reviewManager.activeSheetBinding) { sheet in
                switch sheet {
                case .satisfaction:
                    SatisfactionPromptContent(reviewManager: reviewManager)
                        .interactiveDismissDisabled(true)
                case .feedback:
                    feedbackSheet
                }
            }
    }

    private var feedbackSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tell us what we can improve")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)

                Text("Your feedback goes straight to us — we read every message.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)

                TextEditor(text: $feedbackText)
                    .font(Theme.Font.rowValue)
                    .foregroundStyle(Theme.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                            .strokeBorder(Theme.divider, lineWidth: 1)
                    )

                CinematicPrimaryButton("Send feedback", isDisabled: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    openFeedbackMail()
                    feedbackText = ""
                    reviewManager.feedbackDone()
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.screenH)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        feedbackText = ""
                        reviewManager.feedbackDone()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onDisappear {
            feedbackText = ""
        }
    }

    private func openFeedbackMail() {
        let body = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subject = "MovieMemo feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(ReviewFeedbackConfig.feedbackEmail)?subject=\(subject)&body=\(encoded)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Satisfaction (two steps: question → rate vs written review)

private struct SatisfactionPromptContent: View {
    @ObservedObject var reviewManager: ReviewManager
    @State private var showRatingChoices = false

    var body: some View {
        NavigationView {
            Group {
                if showRatingChoices {
                    positiveFollowUpContent
                } else {
                    initialQuestionContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: reviewManager.activeSheet) { _, new in
            if new != .satisfaction {
                showRatingChoices = false
            }
        }
    }

    private var initialQuestionContent: some View {
        VStack(spacing: 24) {
            Text("Enjoying MovieMemo so far?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            VStack(spacing: 12) {
                CinematicPrimaryButton("Yes, love it ❤️") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRatingChoices = true
                    }
                }
                Button {
                    reviewManager.userTappedNotReally()
                } label: {
                    Text("Not really")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                                .strokeBorder(Theme.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(CinematicScaleButtonStyle())
            }
            .padding(.horizontal, Theme.Spacing.screenH)

            Spacer(minLength: 0)
        }
    }

    private var positiveFollowUpContent: some View {
        VStack(spacing: 20) {
            Text("Thank you!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.primaryText)
                .padding(.top, 8)

            Text("The quick in-app popup only collects star ratings. To write a full review for the App Store, use the button below.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.screenH)

            VStack(spacing: 12) {
                CinematicPrimaryButton("Rate with stars") {
                    reviewManager.requestInAppStarRating()
                }

                if let url = AppStoreConfig.writeReviewURL {
                    Button {
                        UIApplication.shared.open(url)
                        reviewManager.dismissSatisfactionPrompt()
                    } label: {
                        Text("Write a review on the App Store")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                                    .strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(CinematicScaleButtonStyle())
                }

                Button {
                    reviewManager.dismissSatisfactionPrompt()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.tertiaryText)
                }
                .buttonStyle(CinematicScaleButtonStyle())
                .padding(.top, 4)
            }
            .padding(.horizontal, Theme.Spacing.screenH)

            Spacer(minLength: 0)
        }
    }
}
