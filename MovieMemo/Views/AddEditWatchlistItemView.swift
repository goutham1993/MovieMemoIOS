//
//  AddEditWatchlistItemView.swift
//  MovieMemo
//

import SwiftUI

// MARK: - Add / Edit Watchlist Item View

struct AddEditWatchlistItemView: View {
    let item: WatchlistItem?
    let onSave: (WatchlistItem) -> Void
    let onCancel: () -> Void

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var targetDate: Date? = nil
    @State private var language: Language = .english
    @State private var genre: String = ""
    @State private var whereToWatch: WhereToWatch?

    @State private var showWhereSheet = false
    @State private var showLanguageSheet = false
    @State private var showDateSheet = false
    @State private var showMoreDetails = false

    @FocusState private var genreFocused: Bool

    private var isEditing: Bool { item != nil }

    private var isTitleEmpty: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var formattedDate: String {
        guard let date = targetDate else { return "Not set" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.section) {
                        titleSection
                        whereToWatchSection
                        notesSection
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

                    CinematicPrimaryButton(isEditing ? "Save Changes" : "Add to Watchlist", isDisabled: isTitleEmpty) {
                        saveItem()
                    }
                    .padding(.horizontal, Theme.Spacing.screenH)
                    .padding(.bottom, 16)
                    .background(Theme.bg)
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add to Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .sheet(isPresented: $showWhereSheet) {
                WhereToWatchPickerSheet(selection: $whereToWatch)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLanguageSheet) {
                WatchlistLanguagePickerSheet(selection: $language)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showDateSheet) {
                WatchlistDatePickerSheet(selection: $targetDate)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let item { loadItemData(item) }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        CinematicTextField(
            placeholder: "Movie title",
            text: $title,
            font: Theme.Font.inputTitle,
            textAlignment: .center
        )
    }

    private var whereToWatchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where to Watch")
                .font(Theme.Font.sectionHeader)
                .foregroundColor(Theme.secondaryText)

            CinematicSurface {
                CinematicRow(
                    icon: "play.rectangle",
                    label: "Platform",
                    value: whereToWatch?.displayName ?? "Not set"
                ) {
                    showWhereSheet = true
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(Theme.Font.sectionHeader)
                .foregroundColor(Theme.secondaryText)

            CinematicTextField(
                placeholder: "Add notes…",
                text: $notes,
                axis: .vertical
            )
        }
    }

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
                        CinematicRow(
                            icon: "globe",
                            label: "Language",
                            value: language.displayName
                        ) {
                            showLanguageSheet = true
                        }

                        Rectangle().fill(Theme.divider).frame(height: 1)

                        // Genre inline input
                        HStack(spacing: 12) {
                            Image(systemName: "film")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.secondaryText)
                                .frame(width: 24)
                            Text("Genre")
                                .font(Theme.Font.rowLabel)
                                .foregroundColor(Theme.secondaryText)
                            Spacer()
                            TextField("Not set", text: $genre)
                                .font(Theme.Font.rowValue)
                                .foregroundColor(Theme.primaryText)
                                .tint(Theme.accent)
                                .multilineTextAlignment(.trailing)
                                .focused($genreFocused)
                                .submitLabel(.done)
                        }
                        .padding(.vertical, Theme.Spacing.rowPadding)
                        .contentShape(Rectangle())
                        .onTapGesture { genreFocused = true }

                        Rectangle().fill(Theme.divider).frame(height: 1)

                        CinematicRow(
                            icon: "calendar",
                            label: "Release Date",
                            value: formattedDate
                        ) {
                            showDateSheet = true
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Helpers

    private func loadItemData(_ item: WatchlistItem) {
        title = item.title
        notes = item.notes ?? ""
        targetDate = item.targetDate
        language = item.languageEnum
        genre = item.genre ?? ""
        whereToWatch = item.whereToWatch != nil ? WhereToWatch(rawValue: item.whereToWatch!) : nil

        if item.language != Language.english.rawValue || item.genre != nil || item.targetDate != nil {
            showMoreDetails = true
        }
    }

    private func saveItem() {
        let newItem = WatchlistItem(
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes.isEmpty ? nil : notes,
            priority: 2,
            targetDate: targetDate,
            language: language,
            genre: genre.isEmpty ? nil : genre,
            whereToWatch: whereToWatch?.rawValue
        )

        if let original = item {
            newItem.id = original.id
            newItem.createdAt = original.createdAt
        }

        onSave(newItem)
    }
}

// MARK: - Where to Watch Picker Sheet

private struct WhereToWatchPickerSheet: View {
    @Binding var selection: WhereToWatch?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CinematicSheetContainer(title: "Where to Watch") {
            VStack(spacing: 0) {
                CinematicPickerRow(
                    icon: "xmark.circle",
                    label: "Not set",
                    isSelected: selection == nil
                ) {
                    selection = nil
                    dismiss()
                }

                Rectangle().fill(Theme.divider).frame(height: 1)
                    .padding(.leading, Theme.Spacing.screenH)

                ForEach(WhereToWatch.allCases, id: \.self) { option in
                    VStack(spacing: 0) {
                        CinematicPickerRow(
                            icon: option.sfSymbol,
                            label: option.displayName,
                            isSelected: selection == option
                        ) {
                            selection = option
                            dismiss()
                        }
                        if option != WhereToWatch.allCases.last {
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

// MARK: - Language Picker Sheet

private struct WatchlistLanguagePickerSheet: View {
    @Binding var selection: Language
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CinematicSheetContainer(title: "Language") {
            VStack(spacing: 0) {
                ForEach(Language.allCases, id: \.self) { lang in
                    VStack(spacing: 0) {
                        CinematicPickerRow(
                            icon: lang.sfSymbol,
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

// MARK: - Date Picker Sheet

private struct WatchlistDatePickerSheet: View {
    @Binding var selection: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Date

    init(selection: Binding<Date?>) {
        self._selection = selection
        self._draft = State(initialValue: selection.wrappedValue ?? Date())
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DatePicker(
                    "",
                    selection: $draft,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Theme.accent)
                .padding(.horizontal, Theme.Spacing.screenH)

                if selection != nil {
                    Button {
                        selection = nil
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                            Text("Clear Date")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(Theme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                                .strokeBorder(Theme.divider, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.screenH)
                    .padding(.top, 16)
                }

                Spacer()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Release Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selection = draft
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.accent)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.secondaryText)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    AddEditWatchlistItemView(
        item: nil,
        onSave: { _ in },
        onCancel: { }
    )
}
