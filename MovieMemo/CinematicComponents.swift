//
//  CinematicComponents.swift
//  MovieMemo
//

import SwiftUI

// MARK: - Scale Button Style

struct CinematicScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Cinematic Surface

/// A container with `Theme.surface` background, 16pt radius, subtle divider border, and 16pt padding.
struct CinematicSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.surface, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.surface, style: .continuous)
                    .strokeBorder(Theme.divider, lineWidth: 1)
            )
    }
}

// MARK: - Cinematic Row

/// A tappable picker row: SF Symbol + label (13/medium/secondary) + value (17/regular/primary) + chevron.
struct CinematicRow: View {
    let icon: String
    let label: String
    let value: String
    var chevron: Bool = true
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
                    .frame(width: 24)

                Text(label)
                    .font(Theme.Font.rowLabel)
                    .foregroundColor(Theme.secondaryText)

                Spacer()

                Text(value)
                    .font(Theme.Font.rowValue)
                    .foregroundColor(Theme.primaryText)

                if chevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.tertiaryText)
                }
            }
            .padding(.vertical, Theme.Spacing.rowPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(CinematicScaleButtonStyle())
    }
}

// MARK: - Cinematic Row with Divider

/// A `CinematicRow` followed by a `Theme.divider` separator — for use inside a `CinematicSurface`.
struct CinematicDividedRow: View {
    let icon: String
    let label: String
    let value: String
    var showDivider: Bool = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CinematicRow(icon: icon, label: label, value: value, action: action)
            if showDivider {
                Rectangle()
                    .fill(Theme.divider)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Cinematic Text Field

/// A standalone text field with `Theme.surface2` background, 12pt radius, divider border.
struct CinematicTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var font: Font = Theme.Font.rowValue
    var textAlignment: TextAlignment = .leading

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .font(font)
            .multilineTextAlignment(textAlignment)
            .foregroundColor(Theme.primaryText)
            .tint(Theme.accent)
            .padding(Theme.Spacing.rowPadding)
            .background(Theme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                    .strokeBorder(Theme.divider, lineWidth: 1)
            )
    }
}

// MARK: - Cinematic Primary Button

/// Accent-colored primary CTA button. Disabled state uses `opacity(0.35)`.
struct CinematicPrimaryButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    init(_ title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isDisabled { action() }
        }) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "0F0F12"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        }
        .opacity(isDisabled ? 0.35 : 1.0)
        .buttonStyle(CinematicScaleButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Rating Control

/// 5-star rating input. Selected stars use `Theme.accent`, unselected use `Theme.tertiaryText`.
/// Includes a small reset icon button (arrow.counterclockwise) when a rating is set.
struct RatingControl: View {
    @Binding var rating: Int?
    @State private var tappedStar: Int? = nil

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                            tappedStar = star
                            rating = (rating == star * 2) ? nil : star * 2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.spring(response: 0.3)) {
                                tappedStar = nil
                            }
                        }
                    } label: {
                        Image(systemName: (rating ?? 0) >= star * 2 ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundColor(
                                (rating ?? 0) >= star * 2
                                    ? Theme.accent
                                    : Theme.tertiaryText
                            )
                            .scaleEffect(tappedStar == star ? 1.35 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let r = rating {
                HStack(spacing: 8) {
                    Text("\(r / 2) out of 5")
                        .font(Theme.Font.caption)
                        .foregroundColor(Theme.secondaryText)

                    Button {
                        withAnimation(.spring(response: 0.2)) { rating = nil }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .padding(7)
                            .background(Theme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Cinematic Picker Option Row

/// A selection row used inside dark picker sheets.
struct CinematicPickerRow: View {
    let icon: String?
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                        .frame(width: 24)
                }

                Text(label)
                    .font(Theme.Font.rowValue)
                    .foregroundColor(Theme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(.vertical, Theme.Spacing.rowPadding)
            .padding(.horizontal, Theme.Spacing.screenH)
            .contentShape(Rectangle())
        }
        .buttonStyle(CinematicScaleButtonStyle())
    }
}

// MARK: - Cinematic Sheet Container

/// A dark-themed sheet wrapper with drag indicator area and title.
struct CinematicSheetContainer<Content: View>: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: Content

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

