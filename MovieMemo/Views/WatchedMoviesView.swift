//
//  WatchedMoviesView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData
import Combine

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
                                    print("Tapped on movie: \(entry.title)")
                                    print("Before edit - showingAddMovie: \(showingAddMovie)")
                                    viewModel?.editMovie(entry)
                                    print("After edit - showingAddMovie: \(showingAddMovie)")
                                    print("ViewModel editingEntry: \(viewModel?.editingEntry?.title ?? "nil")")
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
                        viewModel?.isShowingAddMovie = true
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
                        if viewModel?.editingEntry != nil {
                            viewModel?.updateMovie(entry)
                        } else {
                            viewModel?.addMovie(entry)
                        }
                        viewModel?.editingEntry = nil
                        viewModel?.isShowingAddMovie = false
                        showingAddMovie = false
                        // Force refresh the UI
                        DispatchQueue.main.async {
                            viewModel?.refreshData()
                        }
                    },
                    onCancel: {
                        viewModel?.editingEntry = nil
                        viewModel?.isShowingAddMovie = false
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
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if let viewModel = viewModel {
                if showingAddMovie != viewModel.isShowingAddMovie {
                    print("Syncing showingAddMovie: \(viewModel.isShowingAddMovie)")
                    showingAddMovie = viewModel.isShowingAddMovie
                }
            }
        }
    }
}

struct WatchedMovieRowView: View {
    let entry: WatchedEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top section with title and rating
            HStack {
                Text(entry.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let rating = entry.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("\(rating)/10")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.brown)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Main content area
            HStack(alignment: .top, spacing: 16) {
                // Left column - Event details
                VStack(alignment: .leading, spacing: 8) {
                    // Date
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(formatDate(entry.watchedDate))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    // Companions
                    if let companions = entry.companions, !companions.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("with \(companions)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Language
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("in \(entry.languageEnum.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    // Location
                    HStack(spacing: 8) {
                        Image(systemName: "location")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("at \(getLocationText())")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    // Notes
                    if let notes = entry.notes, !notes.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Spacer()
                
                // Right column - Additional info
                VStack(alignment: .trailing, spacing: 8) {
                    // Duration
                    if let duration = entry.durationMin, duration > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text("\(duration) min")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Price
                    if let spend = entry.spendCents, spend > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(entry.formattedSpend)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            // Bottom section - Tags
            HStack(spacing: 8) {
                // Genre tag
                if let genre = entry.genre, !genre.isEmpty {
                    Text(genre.lowercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                // Location type tag
                HStack(spacing: 4) {
                    Text(entry.locationTypeEnum.icon)
                        .font(.caption)
                    Text(entry.locationTypeEnum.displayName)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.primary)
                .cornerRadius(8)
                
                // Time of day tag
                Text(entry.timeOfDayEnum.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEEE, MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func getLocationText() -> String {
        if entry.locationTypeEnum == .theater {
            if let theaterName = entry.theaterName, !theaterName.isEmpty {
                return "\(theaterName)\(entry.city != nil ? ", \(entry.city!)" : "")"
            } else {
                return "Theater"
            }
        } else {
            return entry.locationTypeEnum.displayName
        }
    }
}

#Preview {
    WatchedMoviesView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}

