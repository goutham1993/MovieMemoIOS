//
//  WatchedMoviesViewModel.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class WatchedMoviesViewModel: ObservableObject {
    @Published var watchedEntries: [WatchedEntry] = []
    @Published var filteredEntries: [WatchedEntry] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: WatchedFilter = .all
    @Published var sortOption: SortOption = .dateNewest
    @Published var isShowingAddMovie = false
    @Published var editingEntry: WatchedEntry?
    
    private let repository: MovieRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: MovieRepository) {
        self.repository = repository
        setupBindings()
        loadData()
    }
    
    private func setupBindings() {
        // Combine search text and filter changes
        Publishers.CombineLatest3(
            $searchText,
            $selectedFilter,
            $sortOption
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] searchText, filter, sortOption in
            self?.applyFiltersAndSort(searchText: searchText, filter: filter, sortOption: sortOption)
        }
        .store(in: &cancellables)
    }
    
    private func loadData() {
        print("ViewModel: Loading data from repository")
        watchedEntries = repository.getAllWatchedEntries()
        print("ViewModel: Loaded \(watchedEntries.count) entries from repository")
        applyFiltersAndSort()
        print("ViewModel: Applied filters. Filtered entries count: \(filteredEntries.count)")
    }
    
    private func applyFiltersAndSort(searchText: String? = nil, filter: WatchedFilter? = nil, sortOption: SortOption? = nil) {
        let currentSearchText = searchText ?? self.searchText
        let currentFilter = filter ?? self.selectedFilter
        let currentSortOption = sortOption ?? self.sortOption
        
        var entries = repository.getWatchedEntries(filter: currentFilter)
        
        // Apply search filter
        if !currentSearchText.isEmpty {
            entries = repository.searchWatchedEntries(query: currentSearchText)
                .filter { entry in
                    switch currentFilter {
                    case .all:
                        return true
                    case .home:
                        return entry.locationTypeEnum == .home
                    case .theater:
                        return entry.locationTypeEnum == .theater
                    }
                }
        }
        
        // Apply sorting
        entries = sortEntries(entries, by: currentSortOption)
        
        filteredEntries = entries
    }
    
    private func sortEntries(_ entries: [WatchedEntry], by option: SortOption) -> [WatchedEntry] {
        switch option {
        case .dateNewest:
            return entries.sorted { $0.watchedDate > $1.watchedDate }
        case .dateOldest:
            return entries.sorted { $0.watchedDate < $1.watchedDate }
        case .ratingHighest:
            return entries.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .ratingLowest:
            return entries.sorted { ($0.rating ?? 0) < ($1.rating ?? 0) }
        case .amountHighest:
            return entries.sorted { ($0.spendCents ?? 0) > ($1.spendCents ?? 0) }
        case .amountLowest:
            return entries.sorted { ($0.spendCents ?? 0) < ($1.spendCents ?? 0) }
        }
    }
    
    func addMovie(_ entry: WatchedEntry) {
        print("ViewModel: Adding movie - \(entry.title)")
        repository.addWatchedEntry(entry)
        print("ViewModel: Calling loadData after adding movie")
        loadData()
        print("ViewModel: LoadData completed. Current entries count: \(watchedEntries.count)")
    }
    
    func updateMovie(_ entry: WatchedEntry) {
        repository.updateWatchedEntry(entry)
        loadData()
    }
    
    func deleteMovie(_ entry: WatchedEntry) {
        repository.deleteWatchedEntry(entry)
        loadData()
    }
    
    func editMovie(_ entry: WatchedEntry) {
        editingEntry = entry
        isShowingAddMovie = true
    }
    
    func refreshData() {
        loadData()
    }
}

enum SortOption: String, CaseIterable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case ratingHighest = "Rating (Highest)"
    case ratingLowest = "Rating (Lowest)"
    case amountHighest = "Amount (Highest)"
    case amountLowest = "Amount (Lowest)"
    
    var displayName: String {
        return self.rawValue
    }
}

