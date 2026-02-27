//
//  LanguageInsightsCard.swift
//  MovieMemo
//

import SwiftUI

struct LanguageInsightsCard: View {
    let data: InsightsData
    @State private var isExpanded = false
    @State private var showDetail = false
    @State private var animateBars = false

    private var total: Int {
        data.topLanguages.map { $0.count }.reduce(0, +)
    }

    private var displayLanguages: [KeyCount] {
        isExpanded ? data.topLanguages : Array(data.topLanguages.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Language Profile", systemImage: "globe")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showDetail = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if data.topLanguages.isEmpty {
                Text("No language data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(displayLanguages.enumerated()), id: \.element.id) { idx, lang in
                        LanguageRow(
                            rank: idx + 1,
                            language: lang,
                            total: total,
                            animate: animateBars
                        ) {
                            postFilterNotification(filterType: "language", value: lang.category)
                        }
                    }
                }

                if data.topLanguages.count > 3 {
                    Button {
                        withAnimation(.spring(duration: 0.4)) { isExpanded.toggle() }
                    } label: {
                        HStack {
                            Text(isExpanded ? "Show less" : "Show all \(data.topLanguages.count) languages")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if let top = data.topLanguages.first {
                    let pct = total > 0 ? Int(Double(top.count) / Double(total) * 100) : 0
                    insightLine("Mostly \(top.category) (\(pct)%).", icon: "lightbulb")
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .insightDetailsSheet(
            isPresented: $showDetail,
            title: "Language Profile",
            body: "Breakdown of movies by the language you selected when logging. Percentage is out of total movies in this period. Tap a language to filter your Watched list.",
            dateRange: data.dateRange
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.7)) { animateBars = true }
            }
        }
        .onChange(of: data.dateRange) { _, _ in
            animateBars = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.7)) { animateBars = true }
            }
        }
    }
}

// MARK: - Language Row

private struct LanguageRow: View {
    let rank: Int
    let language: KeyCount
    let total: Int
    let animate: Bool
    let onTap: () -> Void

    private var percent: Double {
        total > 0 ? Double(language.count) / Double(total) : 0
    }

    private var barColor: Color {
        let colors: [Color] = [.blue, .teal, .indigo, .purple, .cyan]
        return colors[(rank - 1) % colors.count]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(width: 18, alignment: .trailing)

                    Text(language.category)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(percent * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()

                    Text("(\(language.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.surface2)
                            .frame(height: 6)
                        Capsule()
                            .fill(barColor.gradient)
                            .frame(width: animate ? geo.size.width * percent : 0, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.leading, 26)
            }
        }
        .buttonStyle(.plain)
    }
}
