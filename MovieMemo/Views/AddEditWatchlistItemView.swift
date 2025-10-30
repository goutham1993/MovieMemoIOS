//
//  AddEditWatchlistItemView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI

struct AddEditWatchlistItemView: View {
    let item: WatchlistItem?
    let onSave: (WatchlistItem) -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var targetDate: Date? = nil
    @State private var language: Language = .english
    @State private var hasTargetDate = false
    
    private var isEditing: Bool {
        item != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Required Information") {
                    TextField("Movie Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Language", selection: $language) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text("\(lang.icon) \(lang.displayName)").tag(lang)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Optional Information") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    
                    Toggle("Set Release Date", isOn: $hasTargetDate)
                    
                    if hasTargetDate {
                        DatePicker("Release Date", selection: Binding(
                            get: { targetDate ?? Date() },
                            set: { targetDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add to Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            if let item = item {
                loadItemData(item)
            }
        }
    }
    
    private func loadItemData(_ item: WatchlistItem) {
        title = item.title
        notes = item.notes ?? ""
        targetDate = item.targetDate
        language = item.languageEnum
        hasTargetDate = item.targetDate != nil
    }
    
    private func saveItem() {
        let newItem = WatchlistItem(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            priority: 2, // Default to Medium priority
            targetDate: hasTargetDate ? targetDate : nil,
            language: language
        )
        
        onSave(newItem)
    }
}

#Preview {
    AddEditWatchlistItemView(
        item: nil,
        onSave: { _ in },
        onCancel: { }
    )
}

