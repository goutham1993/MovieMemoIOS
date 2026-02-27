//
//  InsightsRangeSelector.swift
//  MovieMemo
//

import SwiftUI

struct InsightsRangeSelector: View {
    var viewModel: InsightsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Segment buttons
            HStack(spacing: 6) {
                ForEach(InsightsDateRange.segments, id: \.storageKey) { range in
                    SegmentButton(
                        label: range.displayName,
                        isSelected: viewModel.selectedRange == range
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.selectRange(range)
                    }
                }

                // Custom range trigger
                SegmentButton(
                    label: "Custom",
                    isSelected: {
                        if case .custom = viewModel.selectedRange { return true }
                        return false
                    }(),
                    systemImage: "calendar"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.showCustomRangePicker = true
                }
            }
            .padding(.horizontal, 2)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showCustomRangePicker },
            set: { viewModel.showCustomRangePicker = $0 }
        )) {
            CustomRangeSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Segment Button

private struct SegmentButton: View {
    let label: String
    let isSelected: Bool
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                    ? Color.accentColor
                    : Color(.tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Range Sheet

private struct CustomRangeSheet: View {
    var viewModel: InsightsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { viewModel.customRangeStart },
                            set: { viewModel.customRangeStart = $0 }
                        ),
                        displayedComponents: .date
                    )
                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { viewModel.customRangeEnd },
                            set: { viewModel.customRangeEnd = $0 }
                        ),
                        in: viewModel.customRangeStart...,
                        displayedComponents: .date
                    )
                }

                Section {
                    Button("Apply") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.applyCustomRange()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
