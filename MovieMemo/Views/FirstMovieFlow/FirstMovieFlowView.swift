//
//  FirstMovieFlowView.swift
//  MovieMemo
//

import SwiftUI
import SwiftData

private enum FlowStep: Equatable {
    case lastMovieQuestion
    case lastMovieCongrats
    case watchlistQuestion
    case watchlistCongrats
    case favouriteQuestion
    case favouriteCongrats
    case skipped
    case dayPicker
    case notificationConfirm(day: String, weekday: Int?)
    case finalWelcome
}

private enum CongratsType {
    case watched
    case watchlist
    case favourite
}

private struct ReminderDay: Identifiable {
    let id: String
    let label: String
    let icon: String
    let weekday: Int?

    static let all: [ReminderDay] = [
        ReminderDay(id: "friday",   label: "Friday",      icon: "5.circle",  weekday: 6),
        ReminderDay(id: "saturday", label: "Saturday",     icon: "6.circle",  weekday: 7),
        ReminderDay(id: "sunday",   label: "Sunday",       icon: "7.circle",  weekday: 1),
        ReminderDay(id: "weekdays", label: "Weekdays",     icon: "briefcase", weekday: nil),
        ReminderDay(id: "random",   label: "Random days",  icon: "shuffle",   weekday: nil),
    ]
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

            case .lastMovieCongrats:
                congratulationsView(
                    nextLabel: "Continue",
                    onNext: { transitionToQuestion(.watchlistQuestion) }
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

            case .watchlistCongrats:
                congratulationsView(
                    nextLabel: "Continue",
                    onNext: { transitionToQuestion(.favouriteQuestion) }
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

            case .favouriteCongrats:
                congratulationsView(
                    nextLabel: "Continue",
                    onNext: { transitionToQuestion(.dayPicker) }
                )

            case .skipped:
                SkippedContent(onDismiss: { transitionToQuestion(.dayPicker) })

            case .dayPicker:
                DayPickerContent(
                    onSelectDay: { day in
                        transitionTo(.notificationConfirm(day: day.label, weekday: day.weekday))
                    },
                    onSkip: { transitionTo(.finalWelcome) }
                )

            case .notificationConfirm(let dayName, let weekday):
                NotificationConfirmContent(
                    dayName: dayName,
                    onEnable: {
                        NotificationManager.shared.requestAuthorization { granted in
                            if granted {
                                if let wd = weekday {
                                    NotificationManager.shared.scheduleDayReminder(weekday: wd)
                                } else if dayName == "Weekdays" {
                                    for wd in 2...6 {
                                        NotificationManager.shared.scheduleDayReminder(weekday: wd)
                                    }
                                }
                            }
                            transitionTo(.finalWelcome)
                        }
                    },
                    onSkip: { transitionTo(.finalWelcome) }
                )

            case .finalWelcome:
                FinalWelcomeContent(onFinish: {
                    AnalyticsService.shared.track(.firstMovieFlowCompleted)
                    completeFlow()
                })
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
                    transitionTo(.lastMovieCongrats)
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
                    transitionTo(.watchlistCongrats)
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
                    transitionTo(.favouriteCongrats)
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

    // MARK: - Congratulations View

    private func congratulationsView(
        nextLabel: String,
        onNext: @escaping () -> Void
    ) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                CongratsContent(itemTitle: savedItemTitle, type: congratsType)

                Spacer()

                CinematicPrimaryButton(nextLabel) {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onNext()
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

// MARK: - Day Picker Content

private struct DayPickerContent: View {
    let onSelectDay: (ReminderDay) -> Void
    let onSkip: () -> Void

    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(.premiumGold)
                    .padding(.bottom, Theme.Spacing.md)

                Text("When do you usually\nwatch movies?")
                    .font(AppFont.hero)
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)

                Text("We'd love to remind you to log them.")
                    .font(AppFont.body)
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            VStack(spacing: 10) {
                ForEach(ReminderDay.all) { day in
                    Button { onSelectDay(day) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: day.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.premiumGold)
                                .frame(width: 24)

                            Text(day.label)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Theme.primaryText)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.tertiaryText)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                                .strokeBorder(Theme.divider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(CinematicScaleButtonStyle())
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.xl)
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            Spacer()

            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                onSkip()
            } label: {
                Text("Skip")
                    .font(AppFont.body)
                    .foregroundColor(Theme.secondaryText)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .padding(.bottom, Theme.Spacing.xl)
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }
}

// MARK: - Notification Confirm Content

private struct NotificationConfirmContent: View {
    let dayName: String
    let onEnable: () -> Void
    let onSkip: () -> Void

    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 12

    private var reminderText: String {
        if dayName == "Weekdays" {
            return "We'll remind you on weekdays\nto log your movies"
        } else if dayName == "Random days" {
            return "We'll send you a gentle reminder\nto log your movies"
        }
        return "We'll remind you on \(dayName)s\nto log your movies"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(.premiumGold)
                    .padding(.bottom, Theme.Spacing.sm)

                Text(reminderText)
                    .font(AppFont.hero)
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A gentle nudge so you never forget\na movie you watched.")
                    .font(AppFont.body)
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            Spacer()

            VStack(spacing: 12) {
                CinematicPrimaryButton("Enable Reminders") {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onEnable()
                }

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onSkip()
                } label: {
                    Text("Not Now")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(CinematicScaleButtonStyle())
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xxl)
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }
}

// MARK: - Final Welcome Content

private struct FinalWelcomeContent: View {
    let onFinish: () -> Void

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.premiumGold.opacity(0.06), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )
            .opacity(glowOpacity)
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.accent)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .padding(.bottom, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.sm) {
                    Text("You're all set!")
                        .font(AppFont.hero)
                        .foregroundColor(Theme.primaryText)
                        .multilineTextAlignment(.center)

                    Text("Your movie journal is ready.\nStart adding movies whenever you watch them.")
                        .font(AppFont.body)
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .opacity(textOpacity)
                .offset(y: textOffset)

                Text("Your cinematic journey begins now.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.premiumGold.opacity(0.7))
                    .padding(.top, Theme.Spacing.lg)
                    .opacity(textOpacity)

                Spacer()
                Spacer()

                CinematicPrimaryButton("Start Using MovieMemo") {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onFinish()
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xxl)
                .opacity(buttonOpacity)
            }
        }
        .onAppear {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                glowOpacity = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
                textOpacity = 1.0
                textOffset = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.75)) {
                buttonOpacity = 1.0
            }
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
