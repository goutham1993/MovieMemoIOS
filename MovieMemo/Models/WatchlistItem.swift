//
//  WatchlistItem.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation
import SwiftData

@Model
final class WatchlistItem {
    var id: UUID
    var title: String
    var notes: String?
    var priority: Int // 1-3 (High, Medium, Low)
    var createdAt: Date
    var targetDate: Date?
    var language: String // Language raw value
    var genre: String? // Movie genre
    var whereToWatch: String? // Theater, OTT, or Both
    
    init(
        title: String,
        notes: String? = nil,
        priority: Int = 2, // Default to Medium
        targetDate: Date? = nil,
        language: Language,
        genre: String? = nil,
        whereToWatch: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.priority = priority
        self.createdAt = Date()
        self.targetDate = targetDate
        self.language = language.rawValue
        self.genre = genre
        self.whereToWatch = whereToWatch
    }
    
    // Computed properties
    var languageEnum: Language {
        get { Language(rawValue: language) ?? .english }
        set { language = newValue.rawValue }
    }
    
    var priorityDisplayName: String {
        switch priority {
        case 1: return "High"
        case 2: return "Medium"
        case 3: return "Low"
        default: return "Medium"
        }
    }
    
    var priorityIcon: String {
        switch priority {
        case 1: return "exclamationmark.circle.fill"
        case 2: return "clock.fill"
        case 3: return "bubble.left.fill"
        default: return "clock.fill"
        }
    }
}

// MARK: - Where to Watch Options
enum WhereToWatch: String, CaseIterable, Codable {
    case theater = "THEATER"
    case ott = "OTT"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .theater: return "Theater"
        case .ott: return "OTT/Streaming"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .theater: return "🎭"
        case .ott: return "📺"
        case .other: return "📍"
        }
    }

    var sfSymbol: String {
        switch self {
        case .theater: return "theatermasks"
        case .ott: return "tv"
        case .other: return "mappin"
        }
    }
}

