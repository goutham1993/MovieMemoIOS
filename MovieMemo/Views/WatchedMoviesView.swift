//
//  WatchedMoviesView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData

struct WatchedMoviesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WatchedMoviesViewModel?
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: WatchedEntry?
    @State private var showingAddMovie = false
    
    // Computed properties for bindings
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }
    
    private var selectedFilterBinding: Binding<WatchedFilter> {
        Binding(
            get: { viewModel?.selectedFilter ?? .all },
            set: { viewModel?.selectedFilter = $0 }
        )
    }
    
    private var sortOptionBinding: Binding<SortOption> {
        Binding(
            get: { viewModel?.sortOption ?? .dateNewest },
            set: { viewModel?.sortOption = $0 }
        )
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
                        TextField("Search movies...", text: searchTextBinding)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Filter and Sort Controls
                    HStack {
                        // Filter Picker
                        Picker("Filter", selection: selectedFilterBinding) {
                            ForEach(WatchedFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Sort Picker
                        Picker("Sort", selection: sortOptionBinding) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding(.horizontal)
                
                // Movies List
                if viewModel?.filteredEntries.isEmpty == true {
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text((viewModel?.searchText.isEmpty == true) ? "No movies watched yet" : "No movies found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        if viewModel?.searchText.isEmpty == true {
                            Text("Tap the + button to add your first movie!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel?.filteredEntries ?? [], id: \.id) { entry in
                            WatchedMovieRowView(entry: entry)
                                .onTapGesture {
                                    viewModel?.editMovie(entry)
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        viewModel?.editMovie(entry)
                                    }
                                    Button("Delete", role: .destructive) {
                                        entryToDelete = entry
                                        showingDeleteAlert = true
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .onAppear {
                        print("List appeared with \(viewModel?.filteredEntries.count ?? 0) entries")
                    }
                }
            }
            .navigationTitle("Watched Movies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel == nil {
                            viewModel = WatchedMoviesViewModel(repository: MovieRepository(modelContext: modelContext))
                        }
                        showingAddMovie = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMovie) {
                AddEditMovieView(
                    entry: viewModel?.editingEntry,
                    onSave: { entry in
                        print("onSave callback called with entry: \(entry.title)")
                        if viewModel?.editingEntry != nil {
                            print("Updating movie")
                            viewModel?.updateMovie(entry)
                        } else {
                            print("Adding new movie")
                            viewModel?.addMovie(entry)
                        }
                        viewModel?.editingEntry = nil
                        showingAddMovie = false
                        print("Sheet should be dismissed")
                        // Force refresh the UI
                        DispatchQueue.main.async {
                            viewModel?.refreshData()
                        }
                    },
                    onCancel: {
                        viewModel?.editingEntry = nil
                        showingAddMovie = false
                    }
                )
            }
            .alert("Delete Movie", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        viewModel?.deleteMovie(entry)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this movie? This action cannot be undone.")
            }
        }
        .onAppear {
            // Initialize with proper model context
            if viewModel == nil {
                viewModel = WatchedMoviesViewModel(repository: MovieRepository(modelContext: modelContext))
            }
        }
        .onChange(of: showingAddMovie) { _, newValue in
            // Refresh data when the add movie sheet is dismissed
            if !newValue {
                viewModel?.refreshData()
            }
        }
    }
}

struct WatchedMovieRowView: View {
    let entry: WatchedEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text(entry.watchedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let rating = entry.rating {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text(entry.locationTypeEnum.icon)
                        Text(entry.locationTypeEnum.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let spend = entry.spendCents, spend > 0 {
                        Text(entry.formattedSpend)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            if let genre = entry.genre, !genre.isEmpty {
                Text(genre)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchedMoviesView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}

