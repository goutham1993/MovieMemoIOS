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
    @State private var viewModel: WatchlistViewModel?
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: WatchlistItem?
    @State private var showingAddItem = false
    
    // Computed properties for bindings
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }
    
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search watchlist...", text: searchTextBinding)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Watchlist Items
                if viewModel?.filteredItems.isEmpty == true {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text((viewModel?.searchText.isEmpty == true) ? "Your watchlist is empty" : "No items found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        if viewModel?.searchText.isEmpty == true {
                            Text("Tap the + button to add movies to your watchlist!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel?.filteredItems ?? [], id: \.id) { item in
                            WatchlistItemRowView(item: item)
                                .onTapGesture {
                                    viewModel?.editItem(item)
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        viewModel?.editItem(item)
                                    }
                                    Button("Move to Watched") {
                                        viewModel?.moveToWatched(item)
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
                        if viewModel == nil {
                            viewModel = WatchlistViewModel(repository: MovieRepository(modelContext: modelContext))
                        }
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditWatchlistItemView(
                    item: viewModel?.editingItem,
                    onSave: { item in
                        if viewModel?.editingItem != nil {
                            viewModel?.updateItem(item)
                        } else {
                            viewModel?.addItem(item)
                        }
                        viewModel?.editingItem = nil
                        showingAddItem = false
                        // Force refresh the UI
                        DispatchQueue.main.async {
                            viewModel?.refreshData()
                        }
                    },
                    onCancel: {
                        viewModel?.editingItem = nil
                        showingAddItem = false
                    }
                )
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        viewModel?.deleteItem(item)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this item from your watchlist?")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WatchlistViewModel(repository: MovieRepository(modelContext: modelContext))
            }
        }
        .onChange(of: showingAddItem) { _, newValue in
            // Refresh data when the add item sheet is dismissed
            if !newValue {
                viewModel?.refreshData()
            }
        }
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
                        
                        HStack {
                            Text(item.priorityIcon)
                            Text(item.priorityDisplayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                    Text("Target: \(targetDate, style: .date)")
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

