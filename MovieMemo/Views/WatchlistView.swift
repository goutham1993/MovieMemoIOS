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
    
    private var filteredItems: [WatchlistItem] {
        let _ = refreshTrigger // Force recalculation when this changes
        let repository = MovieRepository(modelContext: modelContext)
        var allItems = repository.getAllWatchlistItems()
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break // Show all items
        case .ott:
            allItems = allItems.filter { item in
                guard let whereToWatch = item.whereToWatch,
                      let whereOption = WhereToWatch(rawValue: whereToWatch) else {
                    return false
                }
                return whereOption == .ott
            }
        case .theater:
            allItems = allItems.filter { item in
                guard let whereToWatch = item.whereToWatch,
                      let whereOption = WhereToWatch(rawValue: whereToWatch) else {
                    return false
                }
                return whereOption == .theater
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            allItems = allItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return allItems
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search watchlist...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(WatchlistFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Watchlist Items
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "Your watchlist is empty" : "No items found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        if searchText.isEmpty {
                            Text("Tap the + button to add movies to your watchlist!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems, id: \.id) { item in
                            WatchlistItemRowView(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingItem = item
                                    showingAddItem = true
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        editingItem = item
                                        showingAddItem = true
                                    }
                                    Button("Mark as Complete") {
                                        moveToWatched(item)
                                    }
                                    Button("Delete", role: .destructive) {
                                        itemToDelete = item
                                        showingDeleteAlert = true
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingItem = nil
                        showingAddItem = true
                    }) {
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
                        refreshTrigger += 1 // Trigger UI refresh
                    },
                    onCancel: {
                        editingItem = nil
                        showingAddItem = false
                    }
                )
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        let repository = MovieRepository(modelContext: modelContext)
                        repository.deleteWatchlistItem(item)
                        refreshTrigger += 1 // Trigger UI refresh
                    }
                }
            } message: {
                Text("Are you sure you want to delete this item from your watchlist?")
            }
        }
        .onAppear {
            // Refresh data whenever the view appears
            refreshTrigger += 1
        }
    }
    
    private func moveToWatched(_ item: WatchlistItem) {
        let repository = MovieRepository(modelContext: modelContext)
        _ = repository.moveToWatched(item)
        refreshTrigger += 1 // Trigger UI refresh
    }
}

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
              let whereOption = WhereToWatch(rawValue: whereToWatch) else {
            return false
        }
        return whereOption == .ott
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text(item.languageEnum.flag)
                        Text(item.languageEnum.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Show days to release or "Available to watch now"
                if let days = daysToRelease {
                    if days > 0 {
                        // Future date - show days to release
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(days)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text(days == 1 ? "day" : "days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if days <= 0 && isOTTMovie {
                        // Past or today's date for OTT - show "Available to watch now"
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Available")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text("to watch now")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // Genre and Where to Watch on same row
            HStack(spacing: 12) {
                if let genre = item.genre, !genre.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "film")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(genre)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let whereToWatch = item.whereToWatch, 
                   let whereOption = WhereToWatch(rawValue: whereToWatch) {
                    HStack(spacing: 4) {
                        Text(whereOption.icon)
                            .font(.caption)
                        Text(whereOption.displayName)
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let targetDate = item.targetDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Release: \(targetDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Watchlist Filter
enum WatchlistFilter: String, CaseIterable {
    case all = "All"
    case ott = "OTT"
    case theater = "Theater"
    
    var displayName: String {
        return self.rawValue
    }
}

#Preview {
    WatchlistView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}

