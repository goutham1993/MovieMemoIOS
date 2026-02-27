//
//  AddEditMovieView.swift
//  MovieMemo
//

import SwiftUI

// MARK: - Add/Edit Movie View

struct AddEditMovieView: View {
    let entry: WatchedEntry?
    let onSave: (WatchedEntry) -> Void
    let onCancel: () -> Void

    // Form state
    @State private var title: String = ""
    @State private var rating: Int? = nil
    @State private var watchedDate: Date = Date()
    @State private var locationType: LocationType = .home
    @State private var locationNotes: String = ""
    @State private var companions: String = ""
    @State private var spendDollars: String = ""
    @State private var durationMin: String = ""
    @State private var timeOfDay: TimeOfDay = .evening
    @State private var genre: String = ""
    @State private var notes: String = ""
    @State private var posterUri: String = ""
    @State private var language: Language = .english
    @State private var theaterName: String = ""
    @State private var city: String = ""
    @State private var peopleCountText: String = ""

    // UI state
    @State private var showDatePicker = false
    @State private var showLocationSheet = false
    @State private var showTimeSheet = false
    @State private var showLanguageSheet = false
    @State private var showMoreDetails = false

    private var isEditing: Bool { entry != nil }

    private var isTitleEmpty: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var spendCents: Int? {
        guard let dollars = Double(spendDollars), dollars > 0 else { return nil }
        return Int(dollars * 100)
    }

    private var durationMinutes: Int? {
        guard let minutes = Int(durationMin), minutes > 0 else { return nil }
        return minutes
    }

    private var peopleCount: Int? {
        guard let count = Int(peopleCountText), count > 0 else { return nil }
        return count
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: watchedDate)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.section) {
                        headerSection
                        watchDetailsSection
                        experienceSection
                        moreDetailsSection
                    }
                    .padding(.horizontal, Theme.Spacing.screenH)
                    .padding(.top, 16)
                    .padding(.bottom, 96)
                }
                .scrollDismissesKeyboard(.interactively)

                // Sticky bottom Save button
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Theme.bg.opacity(0), Theme.bg],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 24)

                    CinematicPrimaryButton(isEditing ? "Save Changes" : "Save Movie", isDisabled: isTitleEmpty) {
                        saveMovie()
                    }
                    .padding(.horizontal, Theme.Spacing.screenH)
                    .padding(.bottom, 16)
                    .background(Theme.bg)
                }
            }
            .navigationTitle(isEditing ? "Edit Movie" : "Add Movie")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .sheet(isPresented: $showLocationSheet) {
                LocationPickerSheet(
                    selection: $locationType,
                    theaterName: $theaterName,
                    city: $city,
                    peopleCountText: $peopleCountText
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTimeSheet) {
                TimeOfDayPickerSheet(selection: $timeOfDay)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLanguageSheet) {
                LanguagePickerSheet(selection: $language)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let entry { loadEntryData(entry) }
        }
    }

    // MARK: - Section: Header

    private var headerSection: some View {
        CinematicTextField(
            placeholder: "Movie Title",
            text: $title,
            font: Theme.Font.inputTitle,
            textAlignment: .center
        )
    }

    // MARK: - Section: Watch Details

    private var watchDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch Details")
                .font(Theme.Font.sectionHeader)
                .foregroundColor(Theme.secondaryText)

            CinematicSurface {
                VStack(spacing: 0) {
                    // Date row with inline expandable picker
                    VStack(spacing: 0) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showDatePicker.toggle()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.secondaryText)
                                    .frame(width: 24)

                                Text("Watch Date")
                                    .font(Theme.Font.rowLabel)
                                    .foregroundColor(Theme.secondaryText)

                                Spacer()

                                Text(formattedDate)
                                    .font(Theme.Font.rowValue)
                                    .foregroundColor(Theme.primaryText)

                                Image(systemName: showDatePicker ? "chevron.up" : "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.tertiaryText)
                                    .animation(.easeInOut(duration: 0.2), value: showDatePicker)
                            }
                            .padding(.vertical, Theme.Spacing.rowPadding)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(CinematicScaleButtonStyle())

                        if showDatePicker {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Theme.divider)
                                    .frame(height: 1)
                                DatePicker("", selection: $watchedDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .labelsHidden()
                                    .tint(Theme.accent)
                                    .padding(.bottom, 8)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if !showDatePicker {
                            Rectangle().fill(Theme.divider).frame(height: 1)
                        }
                    }

                    CinematicRow(
                        icon: locationSFSymbol(for: locationType),
                        label: "Location",
                        value: locationType.displayName
                    ) { showLocationSheet = true }

                    Rectangle().fill(Theme.divider).frame(height: 1)

                    CinematicRow(
                        icon: timeSFSymbol(for: timeOfDay),
                        label: "Time of Day",
                        value: timeOfDay.displayName
                    ) { showTimeSheet = true }

                    Rectangle().fill(Theme.divider).frame(height: 1)

                    CinematicRow(
                        icon: "globe",
                        label: "Language",
                        value: language.displayName,
                        chevron: true
                    ) { showLanguageSheet = true }
                }
            }
        }
    }

    // MARK: - Section: Experience

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Experience")
                .font(Theme.Font.sectionHeader)
                .foregroundColor(Theme.secondaryText)

            CinematicSurface {
                VStack(spacing: 0) {
                    // Rating
                    VStack(spacing: 6) {
                        Text("How did you feel?")
                            .font(Theme.Font.rowLabel)
                            .foregroundColor(Theme.secondaryText)

                        RatingControl(rating: $rating)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)

                    Rectangle().fill(Theme.divider).frame(height: 1)

                    // Companions
                    HStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .frame(width: 24)

                        Text("Companions")
                            .font(Theme.Font.rowLabel)
                            .foregroundColor(Theme.secondaryText)

                        Spacer()

                        TextField("Who joined you?", text: $companions)
                            .font(Theme.Font.rowValue)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Theme.primaryText)
                            .tint(Theme.accent)
                    }
                    .padding(.vertical, Theme.Spacing.rowPadding)
                }
            }
        }
    }

    // MARK: - Section: More Details (collapsible)

    private var moreDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showMoreDetails.toggle()
                }
            } label: {
                HStack {
                    Text("More Details")
                        .font(Theme.Font.sectionHeader)
                        .foregroundColor(Theme.secondaryText)
                    Spacer()
                    Image(systemName: showMoreDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.tertiaryText)
                        .animation(.easeInOut(duration: 0.2), value: showMoreDetails)
                }
            }
            .buttonStyle(.plain)

            if showMoreDetails {
                CinematicSurface {
                    VStack(spacing: 0) {
                        inlineInputRow(icon: "tag", label: "Genre", placeholder: "e.g. Action, Drama", text: $genre)
                        Rectangle().fill(Theme.divider).frame(height: 1)

                        // Amount Spent
                        HStack(spacing: 12) {
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.secondaryText)
                                .frame(width: 24)
                            Text("Amount Spent")
                                .font(Theme.Font.rowLabel)
                                .foregroundColor(Theme.secondaryText)
                            Spacer()
                            TextField("0.00", text: $spendDollars)
                                .keyboardType(.decimalPad)
                                .font(Theme.Font.rowValue)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Theme.primaryText)
                                .tint(Theme.accent)
                                .frame(maxWidth: 80)
                            Text("USD")
                                .font(Theme.Font.caption)
                                .foregroundColor(Theme.tertiaryText)
                        }
                        .padding(.vertical, Theme.Spacing.rowPadding)

                        Rectangle().fill(Theme.divider).frame(height: 1)

                        // Duration
                        HStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.secondaryText)
                                .frame(width: 24)
                            Text("Duration")
                                .font(Theme.Font.rowLabel)
                                .foregroundColor(Theme.secondaryText)
                            Spacer()
                            TextField("Minutes", text: $durationMin)
                                .keyboardType(.numberPad)
                                .font(Theme.Font.rowValue)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Theme.primaryText)
                                .tint(Theme.accent)
                                .frame(maxWidth: 80)
                            Text("min")
                                .font(Theme.Font.caption)
                                .foregroundColor(Theme.tertiaryText)
                        }
                        .padding(.vertical, Theme.Spacing.rowPadding)

                        Rectangle().fill(Theme.divider).frame(height: 1)

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.secondaryText)
                                    .frame(width: 24)
                                Text("Notes")
                                    .font(Theme.Font.rowLabel)
                                    .foregroundColor(Theme.secondaryText)
                            }
                            .padding(.top, Theme.Spacing.rowPadding)

                            TextField("Your review or thoughts…", text: $notes, axis: .vertical)
                                .font(Theme.Font.rowValue)
                                .foregroundColor(Theme.primaryText)
                                .tint(Theme.accent)
                                .lineLimit(3...6)
                                .padding(.bottom, Theme.Spacing.rowPadding)
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Inline Input Row Helper

    @ViewBuilder
    private func inlineInputRow(
        icon: String,
        label: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.secondaryText)
                .frame(width: 24)
            Text(label)
                .font(Theme.Font.rowLabel)
                .foregroundColor(Theme.secondaryText)
            Spacer()
            TextField(placeholder, text: text)
                .font(Theme.Font.rowValue)
                .multilineTextAlignment(.trailing)
                .foregroundColor(Theme.primaryText)
                .tint(Theme.accent)
        }
        .padding(.vertical, Theme.Spacing.rowPadding)
    }

    // MARK: - Icon Helpers

    private func locationSFSymbol(for type: LocationType) -> String {
        switch type {
        case .home:        return "house.fill"
        case .theater:     return "building.columns"
        case .friendsHome: return "person.2.fill"
        case .other:       return "mappin"
        }
    }

    private func timeSFSymbol(for time: TimeOfDay) -> String {
        switch time {
        case .morning:   return "sun.horizon"
        case .afternoon: return "sun.max"
        case .evening:   return "sunset"
        case .night:     return "moon.stars"
        }
    }

    // MARK: - Data Loading

    private func loadEntryData(_ entry: WatchedEntry) {
        title = entry.title
        rating = entry.rating
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        watchedDate = f.date(from: entry.watchedDate) ?? Date()
        locationType = entry.locationTypeEnum
        locationNotes = entry.locationNotes ?? ""
        companions = entry.companions ?? ""
        spendDollars = entry.spendCents.map { String(format: "%.2f", Double($0) / 100.0) } ?? ""
        durationMin = entry.durationMin.map { String($0) } ?? ""
        timeOfDay = entry.timeOfDayEnum
        genre = entry.genre ?? ""
        notes = entry.notes ?? ""
        posterUri = entry.posterUri ?? ""
        language = entry.languageEnum
        theaterName = entry.theaterName ?? ""
        city = entry.city ?? ""
        peopleCountText = entry.peopleCount.map { String($0) } ?? ""

        if !genre.isEmpty || !spendDollars.isEmpty || !durationMin.isEmpty || !notes.isEmpty {
            showMoreDetails = true
        }
    }

    // MARK: - Save

    private func saveMovie() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let newEntry = WatchedEntry(
            title: title.trimmingCharacters(in: .whitespaces),
            rating: rating,
            watchedDate: f.string(from: watchedDate),
            locationType: locationType,
            locationNotes: locationNotes.isEmpty ? nil : locationNotes,
            companions: companions.isEmpty ? nil : companions,
            spendCents: spendCents,
            durationMin: durationMinutes,
            timeOfDay: timeOfDay,
            genre: genre.isEmpty ? nil : genre,
            notes: notes.isEmpty ? nil : notes,
            posterUri: posterUri.isEmpty ? nil : posterUri,
            language: language,
            theaterName: theaterName.isEmpty ? nil : theaterName,
            city: city.isEmpty ? nil : city,
            peopleCount: locationType == .theater ? peopleCount : nil
        )

        if let original = entry {
            newEntry.id = original.id
            newEntry.createdAt = original.createdAt
        }

        onSave(newEntry)
    }
}

// MARK: - Location Picker Sheet

private struct LocationPickerSheet: View {
    @Binding var selection: LocationType
    @Binding var theaterName: String
    @Binding var city: String
    @Binding var peopleCountText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CinematicSheetContainer(title: "Location") {
            VStack(spacing: 0) {
                ForEach(LocationType.allCases, id: \.self) { type in
                    VStack(spacing: 0) {
                        CinematicPickerRow(
                            icon: sfSymbol(for: type),
                            label: type.displayName,
                            isSelected: type == selection
                        ) {
                            withAnimation { selection = type }
                        }
                        Rectangle().fill(Theme.divider).frame(height: 1)
                            .padding(.leading, Theme.Spacing.screenH)
                    }
                }

                if selection == .theater {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theater Details")
                            .font(Theme.Font.sectionHeader)
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, Theme.Spacing.screenH)
                            .padding(.top, 24)

                        VStack(spacing: 10) {
                            CinematicTextField(placeholder: "Theater Name", text: $theaterName)
                            CinematicTextField(placeholder: "City", text: $city)
                            HStack(spacing: 12) {
                                Text("People attending")
                                    .font(Theme.Font.rowLabel)
                                    .foregroundColor(Theme.secondaryText)
                                Spacer()
                                TextField("0", text: $peopleCountText)
                                    .keyboardType(.numberPad)
                                    .font(Theme.Font.rowValue)
                                    .foregroundColor(Theme.primaryText)
                                    .tint(Theme.accent)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                    .padding(Theme.Spacing.rowPadding)
                                    .background(Theme.surface2)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                                            .strokeBorder(Theme.divider, lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, Theme.Spacing.screenH)
                        }
                        .padding(.horizontal, Theme.Spacing.screenH)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 8)
        }
    }

    private func sfSymbol(for type: LocationType) -> String {
        switch type {
        case .home:        return "house.fill"
        case .theater:     return "building.columns"
        case .friendsHome: return "person.2.fill"
        case .other:       return "mappin"
        }
    }
}

// MARK: - Time of Day Picker Sheet

private struct TimeOfDayPickerSheet: View {
    @Binding var selection: TimeOfDay
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CinematicSheetContainer(title: "Time of Day") {
            VStack(spacing: 0) {
                ForEach(TimeOfDay.allCases, id: \.self) { time in
                    VStack(spacing: 0) {
                        CinematicPickerRow(
                            icon: sfSymbol(for: time),
                            label: time.displayName,
                            isSelected: time == selection
                        ) {
                            selection = time
                            dismiss()
                        }
                        if time != TimeOfDay.allCases.last {
                            Rectangle().fill(Theme.divider).frame(height: 1)
                                .padding(.leading, Theme.Spacing.screenH)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func sfSymbol(for time: TimeOfDay) -> String {
        switch time {
        case .morning:   return "sun.horizon"
        case .afternoon: return "sun.max"
        case .evening:   return "sunset"
        case .night:     return "moon.stars"
        }
    }
}

// MARK: - Language Picker Sheet

private struct LanguagePickerSheet: View {
    @Binding var selection: Language
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CinematicSheetContainer(title: "Language") {
            VStack(spacing: 0) {
                ForEach(Language.allCases, id: \.self) { lang in
                    VStack(spacing: 0) {
                        CinematicPickerRow(
                            icon: nil,
                            label: lang.displayName,
                            isSelected: lang == selection
                        ) {
                            selection = lang
                            dismiss()
                        }
                        if lang != Language.allCases.last {
                            Rectangle().fill(Theme.divider).frame(height: 1)
                                .padding(.leading, Theme.Spacing.screenH)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    AddEditMovieView(
        entry: nil,
        onSave: { _ in },
        onCancel: { }
    )
}
