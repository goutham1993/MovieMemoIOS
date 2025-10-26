//
//  MovieRepository.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class MovieRepository: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Watched Entries
    
    func getAllWatchedEntries() -> [WatchedEntry] {
        let descriptor = FetchDescriptor<WatchedEntry>(
            sortBy: [SortDescriptor(\.watchedDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getWatchedEntries(filter: WatchedFilter = .all) -> [WatchedEntry] {
        let allEntries = getAllWatchedEntries()
        
        switch filter {
        case .all:
            return allEntries
        case .home:
            return allEntries.filter { $0.locationTypeEnum == .home }
        case .theater:
            return allEntries.filter { $0.locationTypeEnum == .theater }
        }
    }
    
    func searchWatchedEntries(query: String) -> [WatchedEntry] {
        let allEntries = getAllWatchedEntries()
        guard !query.isEmpty else { return allEntries }
        
        return allEntries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query) ||
            (entry.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func addWatchedEntry(_ entry: WatchedEntry) {
        modelContext.insert(entry)
        try? modelContext.save()
    }
    
    func updateWatchedEntry(_ entry: WatchedEntry) {
        // Find the existing entry by ID
        let entryId = entry.id
        let descriptor = FetchDescriptor<WatchedEntry>(
            predicate: #Predicate<WatchedEntry> { watchedEntry in
                watchedEntry.id == entryId
            }
        )
        
        if let existingEntry = try? modelContext.fetch(descriptor).first {
            // Update the existing entry with new values
            existingEntry.title = entry.title
            existingEntry.rating = entry.rating
            existingEntry.watchedDate = entry.watchedDate
            existingEntry.locationType = entry.locationType
            existingEntry.locationNotes = entry.locationNotes
            existingEntry.companions = entry.companions
            existingEntry.spendCents = entry.spendCents
            existingEntry.durationMin = entry.durationMin
            existingEntry.timeOfDay = entry.timeOfDay
            existingEntry.genre = entry.genre
            existingEntry.notes = entry.notes
            existingEntry.posterUri = entry.posterUri
            existingEntry.language = entry.language
            existingEntry.theaterName = entry.theaterName
            existingEntry.city = entry.city
        }
        
        try? modelContext.save()
    }
    
    func deleteWatchedEntry(_ entry: WatchedEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
    
    // MARK: - Watchlist Items
    
    func getAllWatchlistItems() -> [WatchlistItem] {
        let descriptor = FetchDescriptor<WatchlistItem>(
            sortBy: [
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func searchWatchlistItems(query: String) -> [WatchlistItem] {
        let allItems = getAllWatchlistItems()
        guard !query.isEmpty else { return allItems }
        
        return allItems.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            (item.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func addWatchlistItem(_ item: WatchlistItem) {
        modelContext.insert(item)
        try? modelContext.save()
    }
    
    func updateWatchlistItem(_ item: WatchlistItem) {
        try? modelContext.save()
    }
    
    func deleteWatchlistItem(_ item: WatchlistItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }
    
    func moveToWatched(_ item: WatchlistItem) -> WatchedEntry {
        let watchedEntry = WatchedEntry(
            title: item.title,
            watchedDate: DateFormatter.isoDateFormatter.string(from: Date()),
            locationType: .home,
            timeOfDay: .evening, // Default to evening when moving from watchlist
            language: item.languageEnum
        )
        
        // Copy notes if available
        if let notes = item.notes {
            watchedEntry.notes = notes
        }
        
        addWatchedEntry(watchedEntry)
        deleteWatchlistItem(item)
        
        return watchedEntry
    }
    
    // MARK: - Genres
    
    func getAllGenres() -> [Genre] {
        let descriptor = FetchDescriptor<Genre>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addGenre(_ genre: Genre) {
        modelContext.insert(genre)
        try? modelContext.save()
    }
    
    func getGenreSuggestions(for query: String) -> [String] {
        let allGenres = getAllGenres()
        guard !query.isEmpty else { return allGenres.map { $0.name } }
        
        return allGenres
            .map { $0.name }
            .filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    // MARK: - Data Management
    
    func clearAllWatchedEntries() {
        let allEntries = getAllWatchedEntries()
        for entry in allEntries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
    
    func clearAllWatchlistItems() {
        let allItems = getAllWatchlistItems()
        for item in allItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
    
    func exportData() -> Data? {
        let watchedEntries = getAllWatchedEntries()
        let watchlistItems = getAllWatchlistItems()
        let genres = getAllGenres()
        
        print("Export: Found \(watchedEntries.count) watched entries")
        print("Export: Found \(watchlistItems.count) watchlist items")
        print("Export: Found \(genres.count) genres")
        
        let exportData = ExportData(
            watchedEntries: watchedEntries.map { WatchedEntryData(from: $0) },
            watchlistItems: watchlistItems.map { WatchlistItemData(from: $0) },
            genres: genres.map { GenreData(from: $0) },
            exportDate: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(exportData)
            print("Export: Successfully encoded data, size: \(data.count) bytes")
            return data
        } catch {
            print("Export: Failed to encode data: \(error)")
            return nil
        }
    }
    
    func importData(_ data: Data) -> Bool {
        guard let exportData = try? JSONDecoder().decode(ExportData.self, from: data) else {
            return false
        }
        
        // Clear existing data
        clearAllWatchedEntries()
        clearAllWatchlistItems()
        
        // Import new data
        for entryData in exportData.watchedEntries {
            let entry = entryData.toWatchedEntry()
            modelContext.insert(entry)
        }
        
        for itemData in exportData.watchlistItems {
            let item = itemData.toWatchlistItem()
            modelContext.insert(item)
        }
        
        for genreData in exportData.genres {
            let genre = genreData.toGenre()
            modelContext.insert(genre)
        }
        
        try? modelContext.save()
        return true
    }
}

// MARK: - Supporting Types

enum WatchedFilter: String, CaseIterable {
    case all = "All"
    case home = "Home"
    case theater = "Theater"
    
    var displayName: String {
        return self.rawValue
    }
}

struct ExportData: Codable {
    let watchedEntries: [WatchedEntryData]
    let watchlistItems: [WatchlistItemData]
    let genres: [GenreData]
    let exportDate: Date
    let version: String = "1.0"
}

// MARK: - Codable Data Structures for Export/Import

struct WatchedEntryData: Codable {
    let id: UUID
    let title: String
    let rating: Int?
    let watchedDate: String
    let locationType: String
    let locationNotes: String?
    let companions: String?
    let spendCents: Int?
    let durationMin: Int?
    let timeOfDay: String
    let genre: String?
    let notes: String?
    let posterUri: String?
    let language: String
    let theaterName: String?
    let city: String?
    let createdAt: Date
    
    init(from watchedEntry: WatchedEntry) {
        self.id = watchedEntry.id
        self.title = watchedEntry.title
        self.rating = watchedEntry.rating
        self.watchedDate = watchedEntry.watchedDate
        self.locationType = watchedEntry.locationType
        self.locationNotes = watchedEntry.locationNotes
        self.companions = watchedEntry.companions
        self.spendCents = watchedEntry.spendCents
        self.durationMin = watchedEntry.durationMin
        self.timeOfDay = watchedEntry.timeOfDay
        self.genre = watchedEntry.genre
        self.notes = watchedEntry.notes
        self.posterUri = watchedEntry.posterUri
        self.language = watchedEntry.language
        self.theaterName = watchedEntry.theaterName
        self.city = watchedEntry.city
        self.createdAt = watchedEntry.createdAt
    }
    
    func toWatchedEntry() -> WatchedEntry {
        let entry = WatchedEntry(
            title: title,
            rating: rating,
            watchedDate: watchedDate,
            locationType: LocationType(rawValue: locationType) ?? .home,
            locationNotes: locationNotes,
            companions: companions,
            spendCents: spendCents,
            durationMin: durationMin,
            timeOfDay: TimeOfDay(rawValue: timeOfDay) ?? .evening,
            genre: genre,
            notes: notes,
            posterUri: posterUri,
            language: Language(rawValue: language) ?? .english,
            theaterName: theaterName,
            city: city
        )
        entry.id = id
        entry.createdAt = createdAt
        return entry
    }
}

struct WatchlistItemData: Codable {
    let id: UUID
    let title: String
    let notes: String?
    let priority: Int
    let createdAt: Date
    let targetDate: Date?
    let language: String
    
    init(from watchlistItem: WatchlistItem) {
        self.id = watchlistItem.id
        self.title = watchlistItem.title
        self.notes = watchlistItem.notes
        self.priority = watchlistItem.priority
        self.createdAt = watchlistItem.createdAt
        self.targetDate = watchlistItem.targetDate
        self.language = watchlistItem.language
    }
    
    func toWatchlistItem() -> WatchlistItem {
        let item = WatchlistItem(
            title: title,
            notes: notes,
            priority: priority,
            targetDate: targetDate,
            language: Language(rawValue: language) ?? .english
        )
        item.id = id
        item.createdAt = createdAt
        return item
    }
}

struct GenreData: Codable {
    let name: String
    let createdAt: Date
    
    init(from genre: Genre) {
        self.name = genre.name
        self.createdAt = genre.createdAt
    }
    
    func toGenre() -> Genre {
        let genre = Genre(name: name)
        genre.createdAt = createdAt
        return genre
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

