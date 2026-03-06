//
//  FirstMovieFlowView.swift
//  MovieMemo
//

import SwiftUI
import SwiftData

private enum FlowStep {
    case lastMovieQuestion
    case watchlistQuestion
    case favouriteQuestion
    case congratulations
    case skipped
}

private enum CongratsType {
    case watched
    case watchlist
    case favourite
}

struct FirstMovieFlowView: View {
    @AppStorage("hasCompletedFirstMovieFlow") private var hasCompletedFirstMovieFlow = false
    @Environment(\.modelContext) private var modelContext

    @State private var step: FlowStep = .lastMovieQuestion
    @State private var showAddMovieSheet = false
    @State private var showAddWatchlistSheet = false
    @State private var showAddFavouriteSheet = false
    @State private var savedItemTitle: String?
    @State private var congratsType: CongratsType = .watched

    // Staggered animation state
    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var buttonsVisible = false

    var body: some View {
        ZStack {
            CinematicBackgroundView()

            switch step {
            case .lastMovieQuestion:
                questionView(
                    icon: "film.stack",
                    title: "Do you remember the\nlast movie you watched?",
                    subtitle: "Let's start building your movie journal.",
                    yesLabel: "Yes, I do!",
                    noLabel: "Not right now",
                    onYes: { showAddMovieSheet = true },
                    onNo: { transitionToQuestion(.watchlistQuestion) }
                )
            case .watchlistQuestion:
                questionView(
                    icon: "text.badge.star",
                    title: "Any movie you'd like\nto watch next?",
                    subtitle: "Start your watchlist with one pick.",
                    yesLabel: "Yes, I have one!",
                    noLabel: "Not really",
                    onYes: { showAddWatchlistSheet = true },
                    onNo: { transitionToQuestion(.favouriteQuestion) }
                )
            case .favouriteQuestion:
                questionView(
                    icon: "heart.fill",
                    title: "Do you have a\nfavourite movie?",
                    subtitle: "Every great collection starts with a favourite.",
                    yesLabel: "Yes!",
                    noLabel: "Skip for now",
                    onYes: { showAddFavouriteSheet = true },
                    onNo: {
                        AnalyticsService.shared.track(.firstMovieFlowSkipped)
                        transitionTo(.skipped)
                    }
                )
            case .congratulations:
                congratulationsView
            case .skipped:
                SkippedContent(onDismiss: completeFlow)
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

                    savedItemTitle = entry.title
                    congratsType = .watched
                    showAddMovieSheet = false
                    AnalyticsService.shared.track(.firstMovieFlowCompleted)
                    transitionTo(.congratulations)
                },
                onCancel: { showAddMovieSheet = false }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showAddWatchlistSheet) {
            AddEditWatchlistItemView(
                item: nil,
                onSave: { item in
                    let repository = MovieRepository(modelContext: modelContext)
                    AnalyticsService.shared.track(.watchlistItemAdded)
                    repository.addWatchlistItem(item)

                    savedItemTitle = item.title
                    congratsType = .watchlist
                    showAddWatchlistSheet = false
                    AnalyticsService.shared.track(.firstMovieFlowCompleted)
                    transitionTo(.congratulations)
                },
                onCancel: { showAddWatchlistSheet = false }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showAddFavouriteSheet) {
            AddEditMovieView(
                entry: nil,
                onSave: { entry in
                    let repository = MovieRepository(modelContext: modelContext)
                    AnalyticsService.shared.track(.movieAdded, properties: [
                        "has_rating": entry.rating != nil,
                        "has_genre": entry.genre != nil && !entry.genre!.isEmpty,
                        "has_notes": entry.notes != nil && !entry.notes!.isEmpty,
                        "source": "first_movie_flow_favourite"
                    ])
                    repository.addWatchedEntry(entry)
                    ReviewManager.shared.recordMovieLogged()

                    savedItemTitle = entry.title
                    congratsType = .favourite
                    showAddFavouriteSheet = false
                    AnalyticsService.shared.track(.firstMovieFlowCompleted)
                    transitionTo(.congratulations)
                },
                onCancel: { showAddFavouriteSheet = false }
            )
            .preferredColorScheme(.dark)
        }
        .onAppear {
            AnalyticsService.shared.track(.firstMovieFlowStarted)
            animateQuestionIn()
        }
    }

    // MARK: - Reusable Question View

    private func questionView(
        icon: String,
        title: String,
        subtitle: String,
        yesLabel: String,
        noLabel: String,
        onYes: @escaping () -> Void,
        onNo: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.premiumGold)
                .padding(.bottom, Theme.Spacing.xl)
                .opacity(iconVisible ? 1 : 0)
                .offset(y: iconVisible ? 0 : 12)

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(AppFont.hero)
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 12)

                Text(subtitle)
                    .font(AppFont.body)
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .opacity(subtitleVisible ? 1 : 0)
                    .offset(y: subtitleVisible ? 0 : 12)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            VStack(spacing: 12) {
                CinematicPrimaryButton(yesLabel) {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onYes()
                }

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onNo()
                } label: {
                    Text(noLabel)
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

                CongratsContent(itemTitle: savedItemTitle, type: congratsType)

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

    // MARK: - Helpers

    private func transitionTo(_ newStep: FlowStep) {
        resetAnimations()
        withAnimation(.easeOut(duration: 0.4)) {
            step = newStep
        }
    }

    private func transitionToQuestion(_ newStep: FlowStep) {
        resetAnimations()
        withAnimation(.easeOut(duration: 0.4)) {
            step = newStep
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            animateQuestionIn()
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
    let itemTitle: String?
    let type: CongratsType

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20

    private var headlineText: String {
        switch type {
        case .watched:   return "Your first movie is saved!"
        case .watchlist: return "Added to your watchlist!"
        case .favourite: return "Great taste!"
        }
    }

    private var subtitleText: String? {
        guard let title = itemTitle else { return nil }
        switch type {
        case .watched:   return "\"\(title)\" is now part of your journal."
        case .watchlist: return "\"\(title)\" is on your radar."
        case .favourite: return "\"\(title)\" is now part of your journal."
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.accent)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

            VStack(spacing: Theme.Spacing.sm) {
                Text(headlineText)
                    .font(AppFont.hero)
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitleText {
                    Text(subtitle)
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
