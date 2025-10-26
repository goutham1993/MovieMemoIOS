//
//  WatchlistViewModel.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var watchlistItems: [WatchlistItem] = []
    @Published var filteredItems: [WatchlistItem] = []
    @Published var searchText: String = ""
    @Published var isShowingAddItem = false
    @Published var editingItem: WatchlistItem?
    
    private let repository: MovieRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: MovieRepository) {
        self.repository = repository
        setupBindings()
        loadData()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.applySearch(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func loadData() {
        watchlistItems = repository.getAllWatchlistItems()
        applySearch()
    }
    
    private func applySearch(searchText: String? = nil) {
        let currentSearchText = searchText ?? self.searchText
        
        if currentSearchText.isEmpty {
            filteredItems = watchlistItems
        } else {
            filteredItems = repository.searchWatchlistItems(query: currentSearchText)
        }
    }
    
    func addItem(_ item: WatchlistItem) {
        repository.addWatchlistItem(item)
        loadData()
    }
    
    func updateItem(_ item: WatchlistItem) {
        repository.updateWatchlistItem(item)
        loadData()
    }
    
    func deleteItem(_ item: WatchlistItem) {
        repository.deleteWatchlistItem(item)
        loadData()
    }
    
    func editItem(_ item: WatchlistItem) {
        editingItem = item
        isShowingAddItem = true
    }
    
    func moveToWatched(_ item: WatchlistItem) {
        _ = repository.moveToWatched(item)
        loadData()
        // You might want to notify the parent view about this change
    }
    
    func refreshData() {
        loadData()
    }
}

