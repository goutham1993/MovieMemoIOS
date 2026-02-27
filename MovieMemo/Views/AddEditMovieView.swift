//
//  AddEditMovieView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI

// MARK: - Design System

private enum Spacing {
    static let screenHorizontal: CGFloat = 20
    static let sectionVertical: CGFloat = 32
    static let rowVertical: CGFloat = 16
    static let rowPadding: CGFloat = 14
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Movie Row (Reusable)

struct MovieRow: View {
    var label: String
    var value: String
    var icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(value)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.vertical, Spacing.rowPadding)
                Divider()
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

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
    @State private var tappedStar: Int? = nil

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
            ScrollView {
                VStack(spacing: Spacing.sectionVertical) {
                    headerSection
                    watchDetailsSection
                    experienceSection
                    extrasSection
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
            .background(Color(.systemBackground))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit Movie" : "Add Movie")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveMovie)
                        .fontWeight(.semibold)
                        .foregroundColor(isTitleEmpty ? Color(.tertiaryLabel) : Color.accentColor)
                        .disabled(isTitleEmpty)
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
        .onAppear {
            if let entry { loadEntryData(entry) }
        }
    }

    // MARK: - Section: Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                TextField("Movie Title", text: $title)
                    .font(.system(size: 24, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.bottom, 10)
                Rectangle()
                    .fill(isTitleEmpty ? Color(.separator) : Color.accentColor)
                    .frame(height: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isTitleEmpty)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section: Watch Details

    private var watchDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Watch Details")
                .font(.system(size: 20, weight: .semibold))
                .padding(.bottom, Spacing.rowVertical)

            // Date row with inline expandable picker
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showDatePicker.toggle()
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("Watch Date")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedDate)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                            Image(systemName: showDatePicker ? "chevron.up" : "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(.tertiaryLabel))
                                .animation(.easeInOut(duration: 0.2), value: showDatePicker)
                        }
                        .padding(.vertical, Spacing.rowPadding)
                        if !showDatePicker { Divider() }
                    }
                }
                .buttonStyle(ScaleButtonStyle())

                if showDatePicker {
                    VStack(spacing: 0) {
                        DatePicker("", selection: $watchedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .padding(.bottom, 8)
                        Divider()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            MovieRow(
                label: "Location",
                value: locationType.displayName,
                icon: locationSFSymbol(for: locationType)
            ) { showLocationSheet = true }

            MovieRow(
                label: "Time of Day",
                value: timeOfDay.displayName,
                icon: timeSFSymbol(for: timeOfDay)
            ) { showTimeSheet = true }

            MovieRow(
                label: "Language",
                value: language.displayName,
                icon: "globe"
            ) { showLanguageSheet = true }
        }
    }

    // MARK: - Section: Experience

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Experience")
                .font(.system(size: 20, weight: .semibold))
                .padding(.bottom, Spacing.rowVertical)

            // Rating — focal point
            VStack(spacing: 14) {
                Text("How did you feel?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 14) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                                tappedStar = star
                                rating = (rating == star * 2) ? nil : star * 2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation(.spring(response: 0.3)) {
                                    tappedStar = nil
                                }
                            }
                        } label: {
                            Image(systemName: (rating ?? 0) >= star * 2 ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundColor(
                                    (rating ?? 0) >= star * 2
                                        ? Color.accentColor
                                        : Color(.tertiaryLabel)
                                )
                                .scaleEffect(tappedStar == star ? 1.35 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let r = rating {
                    HStack(spacing: 8) {
                        Text("\(r / 2) out of 5")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Button {
                            withAnimation(.spring(response: 0.2)) { rating = nil }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(7)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            Divider()
                .padding(.bottom, Spacing.rowVertical)

            // Companions
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "person.2")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Companions")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("Who joined you?", text: $companions)
                        .font(.system(size: 17))
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, Spacing.rowPadding)
                Divider()
            }
        }
    }

    // MARK: - Section: Extras (More Details)

    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showMoreDetails.toggle()
                }
            } label: {
                HStack {
                    Text("More Details")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: showMoreDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: showMoreDetails)
                }
            }
            .buttonStyle(.plain)

            if showMoreDetails {
                VStack(alignment: .leading, spacing: 0) {
                    inlineInputRow(
                        icon: "tag",
                        label: "Genre",
                        placeholder: "e.g. Action, Drama",
                        text: $genre
                    )

                    // Amount spent
                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("Amount Spent")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("0.00", text: $spendDollars)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 90)
                            Text("USD")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Spacing.rowPadding)
                        Divider()
                    }

                    // Duration
                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: "timer")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("Duration")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("Minutes", text: $durationMin)
                                .keyboardType(.numberPad)
                                .font(.system(size: 17))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 90)
                            Text("min")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Spacing.rowPadding)
                        Divider()
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: "note.text")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("Notes")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, Spacing.rowPadding)

                        TextField("Your review or thoughts...", text: $notes, axis: .vertical)
                            .font(.system(size: 17))
                            .lineLimit(3...6)
                            .padding(.bottom, Spacing.rowPadding)
                        Divider()
                    }
                }
                .padding(.top, Spacing.rowVertical)
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
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                TextField(placeholder, text: text)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, Spacing.rowPadding)
            Divider()
        }
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
        NavigationView {
            List {
                Section {
                    ForEach(LocationType.allCases, id: \.self) { type in
                        Button {
                            withAnimation { selection = type }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: sfSymbol(for: type))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                Text(type.displayName)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)
                                Spacer()
                                if type == selection {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if selection == .theater {
                    Section("Theater Details") {
                        TextField("Theater Name", text: $theaterName)
                        TextField("City", text: $city)
                        HStack {
                            Text("People attending")
                            Spacer()
                            TextField("0", text: $peopleCountText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    }
                }
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
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
        NavigationView {
            List {
                ForEach(TimeOfDay.allCases, id: \.self) { time in
                    Button {
                        selection = time
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: sfSymbol(for: time))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text(time.displayName)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                            Spacer()
                            if time == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Time of Day")
            .navigationBarTitleDisplayMode(.inline)
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
        NavigationView {
            List {
                ForEach(Language.allCases, id: \.self) { lang in
                    Button {
                        selection = lang
                        dismiss()
                    } label: {
                        HStack {
                            Text(lang.displayName)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                            Spacer()
                            if lang == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
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
