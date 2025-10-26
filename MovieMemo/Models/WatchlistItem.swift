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
    
    init(
        title: String,
        notes: String? = nil,
        priority: Int = 2, // Default to Medium
        targetDate: Date? = nil,
        language: Language
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.priority = priority
        self.createdAt = Date()
        self.targetDate = targetDate
        self.language = language.rawValue
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
        case 1: return "🔴"
        case 2: return "🟡"
        case 3: return "🟢"
        default: return "🟡"
        }
    }
}

