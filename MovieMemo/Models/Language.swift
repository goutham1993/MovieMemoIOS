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
    case arabic = "ar"
    case chinese = "zh"
    case dutch = "nl"
    case french = "fr"
    case german = "de"
    case indonesian = "id"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case persian = "fa"
    case polish = "pl"
    case portuguese = "pt"
    case russian = "ru"
    case spanish = "es"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case vietnamese = "vi"
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
        case .arabic: return "العربية"
        case .chinese: return "中文"
        case .dutch: return "Nederlands"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .indonesian: return "Bahasa Indonesia"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .persian: return "فارسی"
        case .polish: return "Polski"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .spanish: return "Español"
        case .thai: return "ไทย"
        case .turkish: return "Türkçe"
        case .ukrainian: return "Українська"
        case .vietnamese: return "Tiếng Việt"
        case .other: return "Other"
        }
    }

    /// English exonyms for picker lists (dropdowns).
    var englishDisplayName: String {
        switch self {
        case .english: return "English"
        case .telugu: return "Telugu"
        case .hindi: return "Hindi"
        case .tamil: return "Tamil"
        case .kannada: return "Kannada"
        case .malayalam: return "Malayalam"
        case .bengali: return "Bengali"
        case .marathi: return "Marathi"
        case .gujarati: return "Gujarati"
        case .punjabi: return "Punjabi"
        case .arabic: return "Arabic"
        case .chinese: return "Chinese"
        case .dutch: return "Dutch"
        case .french: return "French"
        case .german: return "German"
        case .indonesian: return "Indonesian"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .persian: return "Persian (Farsi)"
        case .polish: return "Polish"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .spanish: return "Spanish"
        case .thai: return "Thai"
        case .turkish: return "Turkish"
        case .ukrainian: return "Ukrainian"
        case .vietnamese: return "Vietnamese"
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
        case .arabic: return "🇸🇦"
        case .chinese: return "🇨🇳"
        case .dutch: return "🇳🇱"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .indonesian: return "🇮🇩"
        case .italian: return "🇮🇹"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .persian: return "🇮🇷"
        case .polish: return "🇵🇱"
        case .portuguese: return "🇵🇹"
        case .russian: return "🇷🇺"
        case .spanish: return "🇪🇸"
        case .thai: return "🇹🇭"
        case .turkish: return "🇹🇷"
        case .ukrainian: return "🇺🇦"
        case .vietnamese: return "🇻🇳"
        case .other: return "🌍"
        }
    }

    var icon: String {
        return flag
    }

    var sfSymbol: String {
        return "globe"
    }
}
