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
    @State private var searchText = ""
    @State private var selectedFilter: WatchedFilter = .all
    @State private var sortOption: SortOption = .dateNewest
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: WatchedEntry?
    @State private var showingAddMovie = false
    @State private var editingEntry: WatchedEntry?
    @State private var refreshTrigger = 0

    // Deep-link filter from Insights
    @State private var insightFilterType: String? = nil
    @State private var insightFilterValue: String? = nil
    
    // Simple computed property for filtered entries
    private var filteredEntries: [WatchedEntry] {
        let _ = refreshTrigger // This ensures the computed property recalculates when refreshTrigger changes
        let repository = MovieRepository(modelContext: modelContext)
        var entries = repository.getWatchedEntries(filter: selectedFilter)

        // Apply insight deep-link filter
        if let filterType = insightFilterType, let filterValue = insightFilterValue {
            entries = entries.filter { entry in
                switch filterType {
                case "genre":
                    return entry.genre?.localizedCaseInsensitiveContains(filterValue) ?? false
                case "language":
                    return entry.languageEnum.displayName.localizedCaseInsensitiveContains(filterValue)
                case "companion":
                    guard let companions = entry.companions, !companions.isEmpty else { return false }
                    return companions.localizedCaseInsensitiveContains(filterValue)
                case "location":
                    return entry.locationTypeEnum.displayName.localizedCaseInsensitiveContains(filterValue)
                default:
                    return true
                }
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                (entry.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.companions?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.genre?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.theaterName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.city?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateNewest:
            return entries.sorted { 
                if $0.watchedDate == $1.watchedDate {
                    return $0.createdAt > $1.createdAt // Secondary sort by creation time
                }
                return $0.watchedDate > $1.watchedDate
            }
        case .dateOldest:
            return entries.sorted { 
                if $0.watchedDate == $1.watchedDate {
                    return $0.createdAt < $1.createdAt // Secondary sort by creation time
                }
                return $0.watchedDate < $1.watchedDate
            }
        case .ratingHighest:
            return entries.sorted { 
                if ($0.rating ?? 0) == ($1.rating ?? 0) {
                    return $0.createdAt > $1.createdAt // Secondary sort by creation time
                }
                return ($0.rating ?? 0) > ($1.rating ?? 0)
            }
        case .ratingLowest:
            return entries.sorted { 
                if ($0.rating ?? 0) == ($1.rating ?? 0) {
                    return $0.createdAt > $1.createdAt // Secondary sort by creation time
                }
                return ($0.rating ?? 0) < ($1.rating ?? 0)
            }
        case .amountHighest:
            return entries.sorted { 
                if ($0.spendCents ?? 0) == ($1.spendCents ?? 0) {
                    return $0.createdAt > $1.createdAt // Secondary sort by creation time
                }
                return ($0.spendCents ?? 0) > ($1.spendCents ?? 0)
            }
        case .amountLowest:
            return entries.sorted { 
                if ($0.spendCents ?? 0) == ($1.spendCents ?? 0) {
                    return $0.createdAt > $1.createdAt // Secondary sort by creation time
                }
                return ($0.spendCents ?? 0) < ($1.spendCents ?? 0)
            }
        }
    }
    
    private var thisMonthCount: Int {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let prefix = String(format: "%04d-%02d", year, month)
        return filteredEntries.filter { $0.watchedDate.hasPrefix(prefix) }.count
    }
    
    private var lastMonthCount: Int {
        let now = Date()
        let calendar = Calendar.current
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return 0 }
        let year = calendar.component(.year, from: lastMonth)
        let month = calendar.component(.month, from: lastMonth)
        let prefix = String(format: "%04d-%02d", year, month)
        return filteredEntries.filter { $0.watchedDate.hasPrefix(prefix) }.count
    }
    
    private var totalCount: Int {
        filteredEntries.count
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Insight deep-link filter chip
                    if let filterValue = insightFilterValue, let filterType = insightFilterType {
                        HStack(spacing: 8) {
                            Image(systemName: filterTypeIcon(filterType))
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                            Text("Filtered by: \(filterValue)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    insightFilterType = nil
                                    insightFilterValue = nil
                                    refreshTrigger += 1
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search movies...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Filter and Sort Controls
                    HStack {
                        // Filter Picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(WatchedFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Sort Picker
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack(spacing: 12) {
                        WatchedStatCard(title: "This Month", count: thisMonthCount)
                        WatchedStatCard(title: "Last Month", count: lastMonthCount)
                        WatchedStatCard(title: "Total", count: totalCount)
                    }
                }
                .padding(.horizontal)
                
                // Movies List
                if filteredEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "No movies watched yet" : "No movies found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        if searchText.isEmpty {
                            Text("Tap the + button to add your first movie!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredEntries, id: \.id) { entry in
                            WatchedMovieRowView(entry: entry)
                                .onTapGesture {
                                    editingEntry = entry
                                    showingAddMovie = true
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        editingEntry = entry
                                        showingAddMovie = true
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
                        editingEntry = nil
                        showingAddMovie = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMovie) {
                AddEditMovieView(
                    entry: editingEntry,
                    onSave: { entry in
                        let repository = MovieRepository(modelContext: modelContext)
                        if editingEntry != nil {
                            repository.updateWatchedEntry(entry)
                        } else {
                            repository.addWatchedEntry(entry)
                        }
                        editingEntry = nil
                        showingAddMovie = false
                        // Trigger UI refresh
                        refreshTrigger += 1
                    },
                    onCancel: {
                        editingEntry = nil
                        showingAddMovie = false
                    }
                )
            }
            .alert("Delete Movie", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        let repository = MovieRepository(modelContext: modelContext)
                        repository.deleteWatchedEntry(entry)
                        // Trigger UI refresh
                        refreshTrigger += 1
                    }
                }
            } message: {
                Text("Are you sure you want to delete this movie? This action cannot be undone.")
            }
        }
        .onAppear {
            // Refresh data whenever the view appears
            refreshTrigger += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FilterWatchedMovies"))) { notification in
            guard
                let filterType = notification.userInfo?["filterType"] as? String,
                let value = notification.userInfo?["value"] as? String
            else { return }
            withAnimation(.spring(duration: 0.3)) {
                insightFilterType = filterType
                insightFilterValue = value
            }
            refreshTrigger += 1
        }
    }

    private func filterTypeIcon(_ filterType: String) -> String {
        switch filterType {
        case "genre":       return "tag"
        case "language":    return "globe"
        case "companion":   return "person.2"
        case "location":    return "location"
        default:            return "line.3.horizontal.decrease.circle"
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
                    .background(Color.orange.opacity(0.2))
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
                            .background(Color.orange.opacity(0.2))
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
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(8)
                
                // Time of day tag
                Text(entry.timeOfDayEnum.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
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
            var parts: [String] = []
            
            // Add theater name or default
            if let theaterName = entry.theaterName, !theaterName.isEmpty {
                parts.append(theaterName)
            } else {
                parts.append("Theater")
            }
            
            // Add city if available
            if let city = entry.city, !city.isEmpty {
                parts.append(city)
            }
            
            // Add people count if available
            if let peopleCount = entry.peopleCount, peopleCount > 0 {
                parts.append("(\(peopleCount) \(peopleCount == 1 ? "person" : "people"))")
            }
            
            return parts.joined(separator: ", ")
        } else {
            return entry.locationTypeEnum.displayName
        }
    }
}

private struct WatchedStatCard: View {
    let title: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    WatchedMoviesView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}

