//
//  LocationType.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation

enum LocationType: String, CaseIterable, Codable {
    case home = "HOME"
    case theater = "THEATER"
    case friendsHome = "FRIENDS_HOME"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .theater: return "Theater"
        case .friendsHome: return "Friend's Home"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "🏠"
        case .theater: return "🎭"
        case .friendsHome: return "👥"
        case .other: return "📍"
        }
    }
}

