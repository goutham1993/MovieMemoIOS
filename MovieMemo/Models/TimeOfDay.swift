//
//  TimeOfDay.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation

enum TimeOfDay: String, CaseIterable, Codable {
    case night = "NIGHT"
    case morning = "MORNING"
    case afternoon = "AFTERNOON"
    case evening = "EVENING"
    
    var displayName: String {
        switch self {
        case .night: return "Night"
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        }
    }
    
    var icon: String {
        switch self {
        case .night: return "🌙"
        case .morning: return "🌅"
        case .afternoon: return "☀️"
        case .evening: return "🌆"
        }
    }
}

