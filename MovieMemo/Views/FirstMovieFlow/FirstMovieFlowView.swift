//
//  FirstMovieFlowView.swift
//  MovieMemo
//

import SwiftUI
import SwiftData

struct FirstMovieFlowView: View {
    @AppStorage("hasCompletedFirstMovieFlow") private var hasCompletedFirstMovieFlow = false
    @Environment(\.modelContext) private var modelContext

    @State private var step: FlowStep = .question
    @State private var showAddMovieSheet = false
    @State private var savedMovieTitle: String?

    // Staggered animation state
    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var buttonsVisible = false

    private enum FlowStep {
        case question
        case congratulations
        case skipped
    }

    var body: some View {
        ZStack {
            CinematicBackgroundView()

            switch step {
            case .question:
                questionView
            case .congratulations:
                congratulationsView
            case .skipped:
                skippedView
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddMovieSheet) {
            AddEditMovieView(
                entry: nil,
                onSave: { entry in
                    let repository = MovieRepository(modelContext: modelContext)
                    AnalyticsService.shared.track(.movieAdded, properties: [
                        "has_rating": entry.rating != nil,
                        "has_genre": entry.genre != nil && !entry.genre!.isEmpty,
                        "has_notes": entry.notes != nil && !entry.notes!.isEmpty,
                        "source": "first_movie_flow"
                    ])
                    repository.addWatchedEntry(entry)
                    ReviewManager.shared.recordMovieLogged()

                    savedMovieTitle = entry.title
                    showAddMovieSheet = false

                    AnalyticsService.shared.track(.firstMovieFlowCompleted)
                    transitionTo(.congratulations)
                },
                onCancel: {
                    showAddMovieSheet = false
                }
            )
            .preferredColorScheme(.dark)
        }
        .onAppear {
            AnalyticsService.shared.track(.firstMovieFlowStarted)
            animateQuestionIn()
        }
    }

    // MARK: - Question Step

    private var questionView: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "film.stack")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.premiumGold)
                .padding(.bottom, Theme.Spacing.xl)
                .opacity(iconVisible ? 1 : 0)
                .offset(y: iconVisible ? 0 : 12)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Do you remember the\nlast movie you watched?")
                    .font(AppFont.hero)
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 12)

                Text("Let's start building your movie journal.")
                    .font(AppFont.body)
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .opacity(subtitleVisible ? 1 : 0)
                    .offset(y: subtitleVisible ? 0 : 12)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            VStack(spacing: 12) {
                CinematicPrimaryButton("Yes, I do!") {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showAddMovieSheet = true
                }

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    AnalyticsService.shared.track(.firstMovieFlowSkipped)
                    transitionTo(.skipped)
                } label: {
                    Text("Not right now")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(CinematicScaleButtonStyle())
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xxl)
            .opacity(buttonsVisible ? 1 : 0)
            .offset(y: buttonsVisible ? 0 : 12)
        }
    }

    // MARK: - Congratulations Step

    private var congratulationsView: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                CongratsContent(movieTitle: savedMovieTitle)

                Spacer()

                CinematicPrimaryButton("Let's Go") {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    completeFlow()
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xxl)
            }

            ConfettiView()
        }
    }

    // MARK: - Skipped Step

    private var skippedView: some View {
        SkippedContent(onDismiss: completeFlow)
    }

    // MARK: - Helpers

    private func transitionTo(_ newStep: FlowStep) {
        resetAnimations()
        withAnimation(.easeOut(duration: 0.4)) {
            step = newStep
        }
    }

    private func completeFlow() {
        withAnimation(.easeOut(duration: 0.3)) {
            hasCompletedFirstMovieFlow = true
        }
    }

    private func animateQuestionIn() {
        resetAnimations()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.45))              { iconVisible = true }
            withAnimation(.easeOut(duration: 0.45).delay(0.10)) { titleVisible = true }
            withAnimation(.easeOut(duration: 0.45).delay(0.20)) { subtitleVisible = true }
            withAnimation(.easeOut(duration: 0.45).delay(0.30)) { buttonsVisible = true }
        }
    }

    private func resetAnimations() {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            iconVisible = false
            titleVisible = false
            subtitleVisible = false
            buttonsVisible = false
        }
    }
}

// MARK: - Congratulations Content

private struct CongratsContent: View {
    let movieTitle: String?

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.accent)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Your first movie is saved!")
                    .font(AppFont.hero)
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)

                if let title = movieTitle {
                    Text("\"\(title)\" is now part of your journal.")
                        .font(AppFont.body)
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .opacity(textOpacity)
            .offset(y: textOffset)
        }
        .onAppear {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                textOpacity = 1.0
                textOffset = 0
            }
        }
    }
}

// MARK: - Skipped Content

private struct SkippedContent: View {
    let onDismiss: () -> Void

    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "popcorn")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(.premiumGold)

                VStack(spacing: Theme.Spacing.sm) {
                    Text("No worries!")
                        .font(AppFont.hero)
                        .foregroundColor(Theme.primaryText)

                    Text("Tap  +  anytime to add your first movie.")
                        .font(AppFont.body)
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            Spacer()

            CinematicPrimaryButton("Got it") {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onDismiss()
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xxl)
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }
}
