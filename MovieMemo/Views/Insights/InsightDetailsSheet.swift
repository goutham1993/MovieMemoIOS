//
//  InsightDetailsSheet.swift
//  MovieMemo
//

import SwiftUI

/// Reusable "How is this calculated?" bottom sheet shown from any Insights card.
struct InsightDetailsSheet: View {
    let title: String
    let bodyText: String
    let dateRange: InsightsDateRange

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label(dateRange.displayName, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: Capsule())

                    Divider()

                    Text(bodyText)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Convenience modifier

extension View {
    func insightDetailsSheet(
        isPresented: Binding<Bool>,
        title: String,
        body bodyText: String,
        dateRange: InsightsDateRange
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            InsightDetailsSheet(title: title, bodyText: bodyText, dateRange: dateRange)
        }
    }
}
