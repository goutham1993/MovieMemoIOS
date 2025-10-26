//
//  WatchedEntry.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation
import SwiftData

@Model
final class WatchedEntry {
    var id: UUID
    var title: String
    var rating: Int? // 0-10
    var watchedDate: String // ISO yyyy-MM-dd
    var locationType: String // LocationType raw value
    var locationNotes: String?
    var companions: String? // Comma-separated
    var spendCents: Int? // Stored in cents for precision
    var durationMin: Int?
    var timeOfDay: String // TimeOfDay raw value
    var genre: String?
    var notes: String?
    var posterUri: String?
    var language: String // Language raw value
    var theaterName: String?
    var city: String?
    var createdAt: Date
    
    init(
        title: String,
        rating: Int? = nil,
        watchedDate: String,
        locationType: LocationType,
        locationNotes: String? = nil,
        companions: String? = nil,
        spendCents: Int? = nil,
        durationMin: Int? = nil,
        timeOfDay: TimeOfDay,
        genre: String? = nil,
        notes: String? = nil,
        posterUri: String? = nil,
        language: Language,
        theaterName: String? = nil,
        city: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.rating = rating
        self.watchedDate = watchedDate
        self.locationType = locationType.rawValue
        self.locationNotes = locationNotes
        self.companions = companions
        self.spendCents = spendCents
        self.durationMin = durationMin
        self.timeOfDay = timeOfDay.rawValue
        self.genre = genre
        self.notes = notes
        self.posterUri = posterUri
        self.language = language.rawValue
        self.theaterName = theaterName
        self.city = city
        self.createdAt = Date()
    }
    
    // Computed properties for easy access to enums
    var locationTypeEnum: LocationType {
        get { LocationType(rawValue: locationType) ?? .home }
        set { locationType = newValue.rawValue }
    }
    
    var timeOfDayEnum: TimeOfDay {
        get { TimeOfDay(rawValue: timeOfDay) ?? .evening }
        set { timeOfDay = newValue.rawValue }
    }
    
    var languageEnum: Language {
        get { Language(rawValue: language) ?? .english }
        set { language = newValue.rawValue }
    }
    
    // Helper computed properties
    var formattedSpend: String {
        guard let spendCents = spendCents else { return "N/A" }
        let dollars = Double(spendCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    var formattedDuration: String {
        guard let durationMin = durationMin else { return "N/A" }
        let hours = durationMin / 60
        let minutes = durationMin % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var starRating: String {
        guard let rating = rating else { return "No Rating" }
        return String(repeating: "⭐", count: rating)
    }
}

