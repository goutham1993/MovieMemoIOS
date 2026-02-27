//
//  AddEditMovieView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI

struct AddEditMovieView: View {
    let entry: WatchedEntry?
    let onSave: (WatchedEntry) -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var rating: Int? = nil
    @State private var watchedDate: Date = Date()
    @State private var locationType: LocationType = .home
    @State private var locationNotes: String = ""
    @State private var companions: String = ""
    @State private var spendDollars: String = ""
    @State private var durationMin: String = ""
    @State private var timeOfDay: TimeOfDay = .evening
    @State private var genre: String = ""
    @State private var notes: String = ""
    @State private var posterUri: String = ""
    @State private var language: Language = .english
    @State private var theaterName: String = ""
    @State private var city: String = ""
    @State private var peopleCountText: String = ""
    
    private var isEditing: Bool {
        entry != nil
    }
    
    private var spendCents: Int? {
        guard let dollars = Double(spendDollars), dollars > 0 else { return nil }
        return Int(dollars * 100)
    }
    
    private var durationMinutes: Int? {
        guard let minutes = Int(durationMin), minutes > 0 else { return nil }
        return minutes
    }
    
    private var peopleCount: Int? {
        guard let count = Int(peopleCountText), count > 0 else { return nil }
        return count
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Required Information") {
                    TextField("Movie Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    DatePicker("Watch Date", selection: $watchedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    Picker("Location Type", selection: $locationType) {
                        ForEach(LocationType.allCases, id: \.self) { type in
                            Text("\(type.icon) \(type.displayName)").tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // Theater-specific fields - show immediately after location type
                    if locationType == .theater {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theater Details")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            TextField("Theater Name", text: $theaterName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("City", text: $city)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                Text("How many people?")
                                Spacer()
                                TextField("0", text: $peopleCountText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(8)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity).animation(.easeInOut(duration: 0.3)),
                            removal: .scale(scale: 0.95).combined(with: .opacity).animation(.easeInOut(duration: 0.2))
                        ))
                    }
                    
                    Picker("Time of Day", selection: $timeOfDay) {
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            Text("\(time.icon) \(time.displayName)").tag(time)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Language", selection: $language) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text("\(lang.icon) \(lang.displayName)").tag(lang)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Optional Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star * 2
                                } label: {
                                    Image(systemName: (rating ?? 0) >= star * 2 ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            if let r = rating {
                                Text("\(r / 2)/5")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Clear Rating") {
                                rating = nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    
                    TextField("Genre", text: $genre)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Companions", text: $companions)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Text("Amount Spent")
                        Spacer()
                        TextField("0.00", text: $spendDollars)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("USD")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Minutes", text: $durationMin)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("min")
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("Notes or your review", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
            }
            .navigationTitle(isEditing ? "Edit Movie" : "Add Movie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMovie()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            if let entry = entry {
                loadEntryData(entry)
            }
        }
    }
    
    private func loadEntryData(_ entry: WatchedEntry) {
        title = entry.title
        rating = entry.rating
        watchedDate = DateFormatter.isoDateFormatter.date(from: entry.watchedDate) ?? Date()
        locationType = entry.locationTypeEnum
        locationNotes = entry.locationNotes ?? ""
        companions = entry.companions ?? ""
        spendDollars = entry.spendCents != nil ? String(Double(entry.spendCents!) / 100.0) : ""
        durationMin = entry.durationMin != nil ? String(entry.durationMin!) : ""
        timeOfDay = entry.timeOfDayEnum
        genre = entry.genre ?? ""
        notes = entry.notes ?? ""
        posterUri = entry.posterUri ?? ""
        language = entry.languageEnum
        theaterName = entry.theaterName ?? ""
        city = entry.city ?? ""
        peopleCountText = entry.peopleCount != nil ? String(entry.peopleCount!) : ""
    }
    
    private func saveMovie() {
        let newEntry: WatchedEntry
        if let originalEntry = entry {
            // Editing existing entry - preserve the original ID and createdAt
            newEntry = WatchedEntry(
                title: title,
                rating: rating,
                watchedDate: DateFormatter.isoDateFormatter.string(from: watchedDate),
                locationType: locationType,
                locationNotes: locationNotes.isEmpty ? nil : locationNotes,
                companions: companions.isEmpty ? nil : companions,
                spendCents: spendCents,
                durationMin: durationMinutes,
                timeOfDay: timeOfDay,
                genre: genre.isEmpty ? nil : genre,
                notes: notes.isEmpty ? nil : notes,
                posterUri: posterUri.isEmpty ? nil : posterUri,
                language: language,
                theaterName: theaterName.isEmpty ? nil : theaterName,
                city: city.isEmpty ? nil : city,
                peopleCount: locationType == .theater ? peopleCount : nil
            )
            // Preserve the original ID and createdAt
            newEntry.id = originalEntry.id
            newEntry.createdAt = originalEntry.createdAt
        } else {
            // Creating new entry
            newEntry = WatchedEntry(
                title: title,
                rating: rating,
                watchedDate: DateFormatter.isoDateFormatter.string(from: watchedDate),
                locationType: locationType,
                locationNotes: locationNotes.isEmpty ? nil : locationNotes,
                companions: companions.isEmpty ? nil : companions,
                spendCents: spendCents,
                durationMin: durationMinutes,
                timeOfDay: timeOfDay,
                genre: genre.isEmpty ? nil : genre,
                notes: notes.isEmpty ? nil : notes,
                posterUri: posterUri.isEmpty ? nil : posterUri,
                language: language,
                theaterName: theaterName.isEmpty ? nil : theaterName,
                city: city.isEmpty ? nil : city,
                peopleCount: locationType == .theater ? peopleCount : nil
            )
        }
        
        onSave(newEntry)
    }
}

#Preview {
    AddEditMovieView(
        entry: nil,
        onSave: { _ in },
        onCancel: { }
    )
}

