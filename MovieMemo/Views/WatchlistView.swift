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
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: WatchlistItem?
    @State private var showingAddItem = false
    @State private var editingItem: WatchlistItem?
    @State private var refreshTrigger = 0
    
    private var filteredItems: [WatchlistItem] {
        let _ = refreshTrigger // Force recalculation when this changes
        let repository = MovieRepository(modelContext: modelContext)
        let allItems = repository.getAllWatchlistItems()
        
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search watchlist...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
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

#Preview {
    WatchlistView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}

