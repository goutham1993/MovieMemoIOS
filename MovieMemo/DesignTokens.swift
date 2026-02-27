//
//  DesignTokens.swift
//  MovieMemo
//

import SwiftUI

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme

enum Theme {

    // MARK: Colors

    /// Full-bleed app background
    static let bg          = Color(hex: "0F0F12")
    /// Section / container background
    static let surface     = Color(hex: "17171C")
    /// Cards / elevated surfaces
    static let surface2    = Color(hex: "1E1E24")

    static let primaryText   = Color.white
    static let secondaryText = Color.white.opacity(0.65)
    static let tertiaryText  = Color.white.opacity(0.45)
    static let divider       = Color.white.opacity(0.08)

    /// Cinema gold — use only for primary buttons, selected states, rating stars, small highlights
    static let accent    = Color(hex: "C9A227")
    static let danger    = Color(hex: "FF453A")
    static let disabled  = Color.white.opacity(0.30)

    // MARK: Spacing

    enum Spacing {
        static let screenH:   CGFloat = 20
        static let section:   CGFloat = 28
        static let rowPadding: CGFloat = 14
        static let rowHeight:  CGFloat = 56
    }

    // MARK: Radius

    enum Radius {
        static let field:    CGFloat = 12
        static let surface:  CGFloat = 16
        static let button:   CGFloat = 12
        static let icon:     CGFloat = 10
        static let poster:   CGFloat = 16
    }

    // MARK: Typography

    enum Font {
        static let screenTitle   = SwiftUI.Font.system(size: 34, weight: .bold)
        static let sectionHeader = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let rowLabel      = SwiftUI.Font.system(size: 13, weight: .medium)
        static let rowValue      = SwiftUI.Font.system(size: 17, weight: .regular)
        static let inputTitle    = SwiftUI.Font.system(size: 24, weight: .semibold)
        static let caption       = SwiftUI.Font.system(size: 12, weight: .regular)
    }
}
