//
//  WatchedMoviesView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData
import Combine

struct WatchedMoviesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedFilter: WatchedFilter = .all
    @State private var sortOption: SortOption = .dateNewest
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: WatchedEntry?
    @State private var showingAddMovie = false
    @State private var editingEntry: WatchedEntry?
    @State private var refreshTrigger = 0

    // Deep-link filter from Insights
    @State private var insightFilterType: String? = nil
    @State private var insightFilterValue: String? = nil

    // MARK: - Filtered entries

    private var filteredEntries: [WatchedEntry] {
        let _ = refreshTrigger
        let repository = MovieRepository(modelContext: modelContext)
        var entries = repository.getWatchedEntries(filter: selectedFilter)

        if let filterType = insightFilterType, let filterValue = insightFilterValue {
            entries = entries.filter { entry in
                switch filterType {
                case "genre":
                    return entry.genre?.localizedCaseInsensitiveContains(filterValue) ?? false
                case "language":
                    return entry.languageEnum.displayName.localizedCaseInsensitiveContains(filterValue)
                case "companion":
                    guard let companions = entry.companions, !companions.isEmpty else { return false }
                    return companions.localizedCaseInsensitiveContains(filterValue)
                case "location":
                    return entry.locationTypeEnum.displayName.localizedCaseInsensitiveContains(filterValue)
                default:
                    return true
                }
            }
        }

        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                (entry.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.companions?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.genre?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.theaterName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.city?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        switch sortOption {
        case .dateNewest:
            return entries.sorted {
                if $0.watchedDate == $1.watchedDate { return $0.createdAt > $1.createdAt }
                return $0.watchedDate > $1.watchedDate
            }
        case .dateOldest:
            return entries.sorted {
                if $0.watchedDate == $1.watchedDate { return $0.createdAt < $1.createdAt }
                return $0.watchedDate < $1.watchedDate
            }
        case .ratingHighest:
            return entries.sorted {
                if ($0.rating ?? 0) == ($1.rating ?? 0) { return $0.createdAt > $1.createdAt }
                return ($0.rating ?? 0) > ($1.rating ?? 0)
            }
        case .ratingLowest:
            return entries.sorted {
                if ($0.rating ?? 0) == ($1.rating ?? 0) { return $0.createdAt > $1.createdAt }
                return ($0.rating ?? 0) < ($1.rating ?? 0)
            }
        case .amountHighest:
            return entries.sorted {
                if ($0.spendCents ?? 0) == ($1.spendCents ?? 0) { return $0.createdAt > $1.createdAt }
                return ($0.spendCents ?? 0) > ($1.spendCents ?? 0)
            }
        case .amountLowest:
            return entries.sorted {
                if ($0.spendCents ?? 0) == ($1.spendCents ?? 0) { return $0.createdAt > $1.createdAt }
                return ($0.spendCents ?? 0) < ($1.spendCents ?? 0)
            }
        }
    }

    // MARK: - Stats

    private var thisMonthCount: Int {
        let prefix = currentMonthPrefix()
        return filteredEntries.filter { $0.watchedDate.hasPrefix(prefix) }.count
    }

    private var lastMonthCount: Int {
        guard let prefix = lastMonthPrefix() else { return 0 }
        return filteredEntries.filter { $0.watchedDate.hasPrefix(prefix) }.count
    }

    private var totalCount: Int { filteredEntries.count }

    // MARK: - Smart insight computations

    private var watchTimeThisMonth: String {
        let prefix = currentMonthPrefix()
        let total = filteredEntries
            .filter { $0.watchedDate.hasPrefix(prefix) }
            .compactMap { $0.durationMin }
            .reduce(0, +)
        guard total > 0 else { return "—" }
        let h = total / 60; let m = total % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private var avgRating: String {
        let ratings = filteredEntries.compactMap { $0.rating }
        guard !ratings.isEmpty else { return "—" }
        let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
        return String(format: "%.1f", avg / 2.0)
    }

    private var topGenre: String {
        let genres = filteredEntries.compactMap { $0.genre }.filter { !$0.isEmpty }
        guard !genres.isEmpty else { return "—" }
        let counts = genres.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Controls header section
                Section {
                    VStack(spacing: 12) {
                        // Insight deep-link chip
                        if let filterValue = insightFilterValue, let filterType = insightFilterType {
                            HStack(spacing: 8) {
                                Image(systemName: filterTypeIcon(filterType))
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                                Text("Filtered by: \(filterValue)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.accentColor)
                                Spacer()
                                Button {
                                    withAnimation(.spring(duration: 0.3)) {
                                        insightFilterType = nil
                                        insightFilterValue = nil
                                        refreshTrigger += 1
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Filter + sort row
                        HStack(spacing: 12) {
                            Picker("Filter", selection: $selectedFilter) {
                                ForEach(WatchedFilter.allCases, id: \.self) { filter in
                                    Text(filter.displayName).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("Sort", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        // Unified stats strip
                        InsightStripView(
                            thisMonth: thisMonthCount,
                            lastMonth: lastMonthCount,
                            total: totalCount
                        )

                        // Smart insight mini row
                        InsightMiniRow(
                            watchTime: watchTimeThisMonth,
                            avgRating: avgRating,
                            topGenre: topGenre
                        )
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Movie rows
                if filteredEntries.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "film")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                            Text(searchText.isEmpty ? "No movies watched yet" : "No movies found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            if searchText.isEmpty {
                                Text("Tap + to add your first movie")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredEntries, id: \.id) { entry in
                        WatchedMovieRowView(entry: entry)
                            .onTapGesture {
                                editingEntry = entry
                                showingAddMovie = true
                            }
                            .contextMenu {
                                Button("Edit") {
                                    editingEntry = entry
                                    showingAddMovie = true
                                }
                                Button("Delete", role: .destructive) {
                                    entryToDelete = entry
                                    showingDeleteAlert = true
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editingEntry = entry
                                    showingAddMovie = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.indigo)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Watched")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search movies…")
            .tint(Color.accentColor)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingEntry = nil
                        showingAddMovie = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMovie) {
                AddEditMovieView(
                    entry: editingEntry,
                    onSave: { entry in
                        let repository = MovieRepository(modelContext: modelContext)
                        if editingEntry != nil {
                            repository.updateWatchedEntry(entry)
                        } else {
                            repository.addWatchedEntry(entry)
                        }
                        editingEntry = nil
                        showingAddMovie = false
                        refreshTrigger += 1
                    },
                    onCancel: {
                        editingEntry = nil
                        showingAddMovie = false
                    }
                )
            }
            .alert("Delete Movie", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        let repository = MovieRepository(modelContext: modelContext)
                        repository.deleteWatchedEntry(entry)
                        refreshTrigger += 1
                    }
                }
            } message: {
                Text("Are you sure you want to delete this movie? This action cannot be undone.")
            }
        }
        .onAppear {
            refreshTrigger += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FilterWatchedMovies"))) { notification in
            guard
                let filterType = notification.userInfo?["filterType"] as? String,
                let value = notification.userInfo?["value"] as? String
            else { return }
            withAnimation(.spring(duration: 0.3)) {
                insightFilterType = filterType
                insightFilterValue = value
            }
            refreshTrigger += 1
        }
    }

    // MARK: - Helpers

    private func currentMonthPrefix() -> String {
        let now = Date(); let cal = Calendar.current
        return String(format: "%04d-%02d", cal.component(.year, from: now), cal.component(.month, from: now))
    }

    private func lastMonthPrefix() -> String? {
        let now = Date(); let cal = Calendar.current
        guard let last = cal.date(byAdding: .month, value: -1, to: now) else { return nil }
        return String(format: "%04d-%02d", cal.component(.year, from: last), cal.component(.month, from: last))
    }

    private func filterTypeIcon(_ filterType: String) -> String {
        switch filterType {
        case "genre":       return "tag"
        case "language":    return "globe"
        case "companion":   return "person.2"
        case "location":    return "location"
        default:            return "line.3.horizontal.decrease.circle"
        }
    }
}

// MARK: - Insight Strip

private struct InsightStripView: View {
    let thisMonth: Int
    let lastMonth: Int
    let total: Int

    private var trend: String? {
        guard lastMonth > 0 else { return nil }
        let pct = Int(round(Double(thisMonth - lastMonth) / Double(lastMonth) * 100))
        return pct >= 0 ? "+\(pct)%" : "\(pct)%"
    }

    var body: some View {
        HStack {
            InsightCell(title: "This Month", value: "\(thisMonth)", trend: trend)
            Divider().frame(height: 36)
            InsightCell(title: "Last Month", value: "\(lastMonth)", trend: nil)
            Divider().frame(height: 36)
            InsightCell(title: "Total", value: "\(total)", trend: nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

private struct InsightCell: View {
    let title: String
    let value: String
    let trend: String?

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let t = trend {
                Text(t)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(t.hasPrefix("+") ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Smart Insight Mini Row

private struct InsightMiniRow: View {
    let watchTime: String
    let avgRating: String
    let topGenre: String

    var body: some View {
        HStack(spacing: 0) {
            InsightMiniCell(icon: "clock", value: watchTime, label: "This Month")
            Divider().frame(height: 32)
            InsightMiniCell(icon: "star", value: avgRating, label: "Avg Rating")
            Divider().frame(height: 32)
            InsightMiniCell(icon: "film", value: topGenre, label: "Top Genre")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

private struct InsightMiniCell: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Movie Row Card

struct WatchedMovieRowView: View {
    let entry: WatchedEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title + rating
            HStack(alignment: .top) {
                Text(entry.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if let rating = entry.rating {
                    RatingBadgeView(rating: rating)
                }
            }

            // Metadata labels
            VStack(alignment: .leading, spacing: 5) {
                Label(formatDate(entry.watchedDate), systemImage: "calendar")

                if let companions = entry.companions, !companions.isEmpty {
                    Label("with \(companions)", systemImage: "person.2")
                }

                Label(entry.languageEnum.displayName, systemImage: "globe")
                Label(locationText(), systemImage: locationIcon())

                if let duration = entry.durationMin, duration > 0 {
                    Label(entry.formattedDuration, systemImage: "clock")
                }

                if let spend = entry.spendCents, spend > 0 {
                    Label(entry.formattedSpend, systemImage: "dollarsign.circle")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)

            // Notes preview
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Tag pills
            HStack(spacing: 6) {
                if let genre = entry.genre, !genre.isEmpty {
                    TagPill(text: genre.lowercased())
                }
                TagPill(text: entry.locationTypeEnum.displayName)
                TagPill(text: entry.timeOfDayEnum.displayName)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let display = DateFormatter()
        display.dateFormat = "EEE, MMM d, yyyy"
        return display.string(from: date)
    }

    private func locationText() -> String {
        if entry.locationTypeEnum == .theater {
            var parts: [String] = []
            if let name = entry.theaterName, !name.isEmpty { parts.append(name) } else { parts.append("Theater") }
            if let city = entry.city, !city.isEmpty { parts.append(city) }
            if let count = entry.peopleCount, count > 0 { parts.append("(\(count) \(count == 1 ? "person" : "people"))") }
            return parts.joined(separator: ", ")
        }
        return entry.locationTypeEnum.displayName
    }

    private func locationIcon() -> String {
        switch entry.locationTypeEnum {
        case .theater: return "building.columns"
        case .home: return "house"
        case .friendsHome: return "person.2.fill"
        case .other: return "mappin"
        }
    }
}

// MARK: - Rating Badge

private struct RatingBadgeView: View {
    let rating: Int

    var body: some View {
        Text(String(format: "%.1f", Double(rating) / 2.0))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.15))
            .foregroundStyle(Color(red: 0.8, green: 0.65, blue: 0))
            .clipShape(Capsule())
    }
}

// MARK: - Tag Pill

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
            .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    WatchedMoviesView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}
