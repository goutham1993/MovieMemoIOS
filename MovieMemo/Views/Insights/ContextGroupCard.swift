//
//  ContextGroupCard.swift
//  MovieMemo
//  Companion + Location combined "Context" section.
//

import SwiftUI

// MARK: - Location Item (file-private data type)

private struct LocationItem {
    let name: String
    let count: Int
    let icon: String
    let color: Color
}

// MARK: - Main Card

private enum ContextDetailType: Identifiable {
    case companion, location
    var id: String { switch self { case .companion: return "companion"; case .location: return "location" } }
}

struct ContextGroupCard: View {
    let data: InsightsData
    @State private var activeDetail: ContextDetailType?
    @State private var animateBars = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Context", systemImage: "person.2")
                .font(.title3)
                .fontWeight(.bold)

            Divider()

            companionSection

            Divider()

            locationSection
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .sheet(item: $activeDetail) { detail in
            switch detail {
            case .companion:
                InsightDetailsSheet(
                    title: "Companion",
                    bodyText: "Counts how many movies you watched with each companion (from the companions field). Solo movies (no companion entered) are not shown here. Tap a name to filter your Watched list.",
                    dateRange: data.dateRange
                )
            case .location:
                InsightDetailsSheet(
                    title: "Location",
                    bodyText: "Splits movies by where you watched them: Home, Theater, Friend's Home, or Other. For theater movies with spend data, the average per-visit spend is shown. Tap a location to filter.",
                    dateRange: data.dateRange
                )
            }
        }
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

    // MARK: - Companion

    private var companionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Companion", systemImage: "person.2.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    activeDetail = .companion
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            if data.companions.isEmpty {
                Text("No companion data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                let topCompanions = Array(data.companions.prefix(3))
                let companionTotal = topCompanions.map { $0.count }.reduce(0, +)

                VStack(spacing: 8) {
                    ForEach(topCompanions) { companion in
                        CompanionRow(
                            companion: companion,
                            total: companionTotal,
                            animate: animateBars
                        ) {
                            postFilterNotification(filterType: "companion", value: companion.category)
                        }
                    }
                }

                if let top = data.companions.first {
                    let pct = data.moviesCount > 0 ? Int(Double(top.count) / Double(data.moviesCount) * 100) : 0
                    insightLine("Mostly watched with \(top.category) (\(pct)% of movies).", icon: "lightbulb")
                }
            }
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        let locationItems = buildLocationItems()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Location", systemImage: "location.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    activeDetail = .location
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            if locationItems.isEmpty {
                Text("No location data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                let locTotal = locationItems.map { $0.count }.reduce(0, +)

                VStack(spacing: 8) {
                    ForEach(locationItems, id: \.name) { item in
                        LocationRow(item: item, total: locTotal, animate: animateBars) {
                            postFilterNotification(filterType: "location", value: item.name)
                        }
                    }
                }

                if data.theaterCount > 0 && data.theaterAvgSpendCents > 0 {
                    insightLine("Theater avg: \(formatCents(data.theaterAvgSpendCents)) per movie.", icon: "dollarsign.circle")
                }

                let homeTotal = data.homeCount + data.friendsHomeCount
                if homeTotal > 0 && data.moviesCount > 0 {
                    let pct = Int(Double(homeTotal) / Double(data.moviesCount) * 100)
                    insightLine("You prefer watching at home (\(pct)%).", icon: "lightbulb")
                }
            }
        }
    }

    private func buildLocationItems() -> [LocationItem] {
        var items: [LocationItem] = []
        if data.homeCount > 0 {
            items.append(LocationItem(name: "Home", count: data.homeCount, icon: "house.fill", color: .blue))
        }
        if data.theaterCount > 0 {
            items.append(LocationItem(name: "Theater", count: data.theaterCount, icon: "ticket.fill", color: .red))
        }
        if data.friendsHomeCount > 0 {
            items.append(LocationItem(name: "Friend's Home", count: data.friendsHomeCount, icon: "person.2.fill", color: .orange))
        }
        if data.otherCount > 0 {
            items.append(LocationItem(name: "Other", count: data.otherCount, icon: "mappin", color: .gray))
        }
        return items.sorted { $0.count > $1.count }
    }

    private func formatCents(_ cents: Int) -> String {
        String(format: "$%.2f", Double(cents) / 100.0)
    }
}

// MARK: - Companion Row

private struct CompanionRow: View {
    let companion: KeyCount
    let total: Int
    let animate: Bool
    let onTap: () -> Void

    private var percent: Double {
        total > 0 ? Double(companion.count) / Double(total) : 0
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(companion.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(companion.count) movies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemFill)).frame(height: 6)
                        Capsule().fill(Color.blue.gradient)
                            .frame(width: animate ? geo.size.width * percent : 0, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Row

private struct LocationRow: View {
    let item: LocationItem
    let total: Int
    let animate: Bool
    let onTap: () -> Void

    private var percent: Double {
        total > 0 ? Double(item.count) / Double(total) : 0
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Image(systemName: item.icon)
                        .foregroundStyle(item.color)
                        .font(.caption)
                        .frame(width: 16)
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(percent * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text("(\(item.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemFill)).frame(height: 6)
                        Capsule().fill(item.color.gradient)
                            .frame(width: animate ? geo.size.width * percent : 0, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.leading, 24)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Notification Helper (shared across Insights cards)

func postFilterNotification(filterType: String, value: String) {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    NotificationCenter.default.post(
        name: NSNotification.Name("FilterWatchedMovies"),
        object: nil,
        userInfo: ["filterType": filterType, "value": value]
    )
}
