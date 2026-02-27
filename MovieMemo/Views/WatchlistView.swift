//
//  WatchlistView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedFilter: WatchlistFilter = .all
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: WatchlistItem?
    @State private var showingAddItem = false
    @State private var editingItem: WatchlistItem?
    @State private var refreshTrigger = 0
    @State private var isEditing = false
    @State private var displayItems: [WatchlistItem] = []

    private var filteredItems: [WatchlistItem] {
        let _ = refreshTrigger
        let repository = MovieRepository(modelContext: modelContext)
        var allItems = repository.getAllWatchlistItems()

        switch selectedFilter {
        case .all:
            break
        case .ott:
            allItems = allItems.filter { item in
                guard let whereToWatch = item.whereToWatch,
                      let whereOption = WhereToWatch(rawValue: whereToWatch) else { return false }
                return whereOption == .ott
            }
        case .theater:
            allItems = allItems.filter { item in
                guard let whereToWatch = item.whereToWatch,
                      let whereOption = WhereToWatch(rawValue: whereToWatch) else { return false }
                return whereOption == .theater
            }
        }

        if !searchText.isEmpty {
            allItems = allItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return allItems
    }

    private var theaterCount: Int {
        displayItems.filter { item in
            guard let w = item.whereToWatch, let opt = WhereToWatch(rawValue: w) else { return false }
            return opt == .theater
        }.count
    }

    private var ottCount: Int {
        displayItems.filter { item in
            guard let w = item.whereToWatch, let opt = WhereToWatch(rawValue: w) else { return false }
            return opt == .ott
        }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Filter
                Picker("Type", selection: $selectedFilter) {
                    ForEach(WatchlistFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)

                if displayItems.isEmpty {
                    emptyStateView
                } else {
                    // Quick Insights Row
                    HStack(spacing: 0) {
                        InsightMini(icon: "film", value: "\(displayItems.count)", label: "Total")
                        Divider().frame(height: 32)
                        InsightMini(icon: "theatermasks", value: "\(theaterCount)", label: "Theater")
                        Divider().frame(height: 32)
                        InsightMini(icon: "tv", value: "\(ottCount)", label: "Streaming")
                    }
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.divider, lineWidth: 1))
                    .padding(.horizontal)

                    // Subtext
                    Text("\(displayItems.count) \(displayItems.count == 1 ? "movie" : "movies") waiting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 2)

                    List {
                        ForEach(displayItems, id: \.id) { item in
                            WatchlistItemRowView(item: item)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingItem = item
                                    showingAddItem = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        itemToDelete = item
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        moveToWatched(item)
                                    } label: {
                                        Label("Mark Watched", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingItem = item
                                        showingAddItem = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onMove(perform: moveItem)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Theme.bg)
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !displayItems.isEmpty {
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation { isEditing.toggle() }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingItem = nil
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditWatchlistItemView(
                    item: editingItem,
                    onSave: { item in
                        let repository = MovieRepository(modelContext: modelContext)
                        if editingItem != nil {
                            repository.updateWatchlistItem(item)
                        } else {
                            repository.addWatchlistItem(item)
                        }
                        editingItem = nil
                        showingAddItem = false
                        refreshTrigger += 1
                    },
                    onCancel: {
                        editingItem = nil
                        showingAddItem = false
                    }
                )
                .preferredColorScheme(.dark)
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        let repository = MovieRepository(modelContext: modelContext)
                        repository.deleteWatchlistItem(item)
                        refreshTrigger += 1
                    }
                }
            } message: {
                Text("Are you sure you want to delete this item from your watchlist?")
            }
            .onAppear {
                refreshTrigger += 1
            }
            .onChange(of: refreshTrigger) { _, _ in
                displayItems = filteredItems
            }
            .onChange(of: searchText) { _, _ in
                displayItems = filteredItems
            }
            .onChange(of: selectedFilter) { _, _ in
                displayItems = filteredItems
            }
        }
        .tint(Color.accentColor)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "film")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "Your watchlist is empty" : "No items found")
                .font(.title3.weight(.semibold))
            Text(searchText.isEmpty ? "Add movies you want to watch." : "Try a different search term.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func moveToWatched(_ item: WatchlistItem) {
        let repository = MovieRepository(modelContext: modelContext)
        _ = repository.moveToWatched(item)
        refreshTrigger += 1
    }

    private func moveItem(from source: IndexSet, to destination: Int) {
        displayItems.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Insight Mini
struct InsightMini: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Platform Tag View
struct PlatformTagView: View {
    let type: WhereToWatch

    var body: some View {
        Label(type.displayName, systemImage: type.sfSymbol)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        .background(Theme.accent.opacity(0.12))
        .foregroundStyle(Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Priority Dot View
struct PriorityDotView: View {
    let priority: Int

    private var color: Color {
        switch priority {
        case 1: return .orange
        case 2: return Color(red: 0.85, green: 0.65, blue: 0.0)
        default: return Color(.tertiaryLabel)
        }
    }

    private var label: String {
        switch priority {
        case 1: return "High Priority"
        case 2: return "Soon"
        default: return "Casual"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Watchlist Item Row View
struct WatchlistItemRowView: View {
    let item: WatchlistItem

    private var daysToRelease: Int? {
        guard let targetDate = item.targetDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let releaseDate = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: today, to: releaseDate)
        return components.day
    }

    private var isOTTMovie: Bool {
        guard let whereToWatch = item.whereToWatch,
              let whereOption = WhereToWatch(rawValue: whereToWatch) else { return false }
        return whereOption == .ott
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title + Priority
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                Spacer(minLength: 8)
                PriorityDotView(priority: item.priority)
            }

            // Language + Platform tag
            HStack(spacing: 8) {
                Text(item.languageEnum.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let whereToWatch = item.whereToWatch,
                   let opt = WhereToWatch(rawValue: whereToWatch) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    PlatformTagView(type: opt)
                }
            }

            // Genre
            if let genre = item.genre, !genre.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "film")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(genre)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Notes preview
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Release / availability
            if let days = daysToRelease {
                if days > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(days) \(days == 1 ? "day" : "days") to release")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                } else if isOTTMovie {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("Available to watch now")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            } else if let targetDate = item.targetDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("Release: \(targetDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.divider, lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Watchlist Filter
enum WatchlistFilter: String, CaseIterable {
    case all = "All"
    case ott = "OTT"
    case theater = "Theater"

    var displayName: String { rawValue }
}

#Preview {
    WatchlistView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}
