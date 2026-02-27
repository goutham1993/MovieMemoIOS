//
//  AddEditWatchlistItemView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI

// MARK: - Design Tokens

private enum WS {
    static let screenH: CGFloat = 20
    static let sectionSpacing: CGFloat = 28
    static let rowPadding: CGFloat = 14
}

// MARK: - Scale Button Style

private struct WatchlistScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Premium Row

private struct PremiumRow: View {
    let icon: String
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
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
                .padding(.vertical, WS.rowPadding)
                Divider()
            }
        }
        .buttonStyle(WatchlistScaleButtonStyle())
    }
}

// MARK: - Section Header

private struct WatchlistSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.bottom, 8)
    }
}

// MARK: - Collapsible Section

private struct CollapsibleSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @State private var isExpanded = false

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Where to Watch Picker Sheet

private struct WhereToWatchPickerSheet: View {
    @Binding var selection: WhereToWatch?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Button {
                    selection = nil
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        Text("Not set")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                        Spacer()
                        if selection == nil {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }

                ForEach(WhereToWatch.allCases, id: \.self) { option in
                    Button {
                        selection = option
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: option.sfSymbol)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text(option.displayName)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                            Spacer()
                            if selection == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Where to Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Language Picker Sheet

private struct WatchlistLanguagePickerSheet: View {
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
                        HStack(spacing: 14) {
                            Image(systemName: lang.sfSymbol)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
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
                .padding(.horizontal, WS.screenH)

                if selection != nil {
                    Button(role: .destructive) {
                        selection = nil
                        dismiss()
                    } label: {
                        Text("Clear Date")
                            .font(.system(size: 17))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .padding(.horizontal, WS.screenH)
                }

                Spacer()
            }
            .navigationTitle("Release Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selection = draft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

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

    @FocusState private var genreFocused: Bool

    private var isEditing: Bool { item != nil }

    private var formattedDate: String {
        guard let date = targetDate else { return "Not set" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: WS.sectionSpacing) {

                    // 1. Movie Title
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Movie title", text: $title)
                            .font(.system(size: 24, weight: .semibold))
                            .submitLabel(.done)
                        Divider()
                    }

                    // 2. Where to Watch
                    VStack(spacing: 0) {
                        WatchlistSectionHeader("Where to Watch")
                        PremiumRow(
                            icon: "tv",
                            label: "Platform",
                            value: whereToWatch?.displayName ?? "Not set"
                        ) {
                            showWhereSheet = true
                        }
                    }

                    // 3. Notes
                    VStack(alignment: .leading, spacing: 6) {
                        WatchlistSectionHeader("Notes")
                        TextField("Add notes…", text: $notes, axis: .vertical)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .lineLimit(3...8)
                        Divider()
                    }

                    // 4. More Details (collapsible)
                    CollapsibleSection("More details") {
                        PremiumRow(
                            icon: "globe",
                            label: "Language",
                            value: language.displayName
                        ) {
                            showLanguageSheet = true
                        }

                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                Image(systemName: "film")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                Text("Genre")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("Not set", text: $genre)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.trailing)
                                    .focused($genreFocused)
                                    .submitLabel(.done)
                            }
                            .padding(.vertical, WS.rowPadding)
                            .contentShape(Rectangle())
                            .onTapGesture { genreFocused = true }
                            Divider()
                        }

                        PremiumRow(
                            icon: "calendar",
                            label: "Release Date",
                            value: formattedDate
                        ) {
                            showDateSheet = true
                        }
                    }
                }
                .padding(.horizontal, WS.screenH)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add to Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveItem() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showWhereSheet) {
                WhereToWatchPickerSheet(selection: $whereToWatch)
            }
            .sheet(isPresented: $showLanguageSheet) {
                WatchlistLanguagePickerSheet(selection: $language)
            }
            .sheet(isPresented: $showDateSheet) {
                WatchlistDatePickerSheet(selection: $targetDate)
            }
        }
        .onAppear {
            if let item { loadItemData(item) }
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

// MARK: - Preview

#Preview {
    AddEditWatchlistItemView(
        item: nil,
        onSave: { _ in },
        onCancel: { }
    )
}
