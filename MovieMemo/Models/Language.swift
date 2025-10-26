//
//  Language.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation

enum Language: String, CaseIterable, Codable {
    case english = "en"
    case telugu = "te"
    case hindi = "hi"
    case tamil = "ta"
    case kannada = "kn"
    case malayalam = "ml"
    case bengali = "bn"
    case marathi = "mr"
    case gujarati = "gu"
    case punjabi = "pa"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .telugu: return "తెలుగు"
        case .hindi: return "हिन्दी"
        case .tamil: return "தமிழ்"
        case .kannada: return "ಕನ್ನಡ"
        case .malayalam: return "മലയാളം"
        case .bengali: return "বাংলা"
        case .marathi: return "मराठी"
        case .gujarati: return "ગુજરાતી"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .other: return "Other"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .telugu: return "🇮🇳"
        case .hindi: return "🇮🇳"
        case .tamil: return "🇮🇳"
        case .kannada: return "🇮🇳"
        case .malayalam: return "🇮🇳"
        case .bengali: return "🇮🇳"
        case .marathi: return "🇮🇳"
        case .gujarati: return "🇮🇳"
        case .punjabi: return "🇮🇳"
        case .other: return "🌍"
        }
    }
    
    var icon: String {
        return flag
    }
}

