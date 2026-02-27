//
//  TopGenresCard.swift
//  MovieMemo
//

import SwiftUI

struct TopGenresCard: View {
    let data: InsightsData
    @State private var isExpanded = false
    @State private var showDetail = false
    @State private var animateBars = false

    private var displayGenres: [KeyCount] {
        isExpanded ? data.topGenres : Array(data.topGenres.prefix(5))
    }

    private var total: Int {
        data.topGenres.map { $0.count }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Taste Profile", systemImage: "tag")
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

            Text("Top Genres")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if data.topGenres.isEmpty {
                Text("No genre data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(displayGenres.enumerated()), id: \.element.id) { idx, genre in
                        GenreRow(
                            rank: idx + 1,
                            genre: genre,
                            total: total,
                            animate: animateBars
                        ) {
                            postFilterNotification(filterType: "genre", value: genre.category)
                        }
                    }
                }

                // Show all / Show less
                if data.topGenres.count > 5 {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text(isExpanded ? "Show less" : "Show all \(data.topGenres.count) genres")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Insight line
                if let top = data.topGenres.first {
                    let pct = total > 0 ? Int(Double(top.count) / Double(total) * 100) : 0
                    insightLine("\(top.category) is your #1 genre (\(pct)%).", icon: "lightbulb")
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .insightDetailsSheet(
            isPresented: $showDetail,
            title: "Top Genres",
            body: "Ranks genres by how many movies in this period have that genre tag. Percentage is out of all movies with a genre. Tap a genre to filter your Watched list.",
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

// MARK: - Genre Row

private struct GenreRow: View {
    let rank: Int
    let genre: KeyCount
    let total: Int
    let animate: Bool
    let onTap: () -> Void

    private var percent: Double {
        total > 0 ? Double(genre.count) / Double(total) : 0
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

                    Text(genre.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    Text("\(Int(percent * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()

                    Text("(\(genre.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 6)
                        Capsule()
                            .fill(Color.accentColor.gradient)
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
