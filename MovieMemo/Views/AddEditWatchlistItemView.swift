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
    @State private var priority: Int = 2 // Default to Medium
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
                            HStack {
                                Text(lang.flag)
                                Text(lang.displayName)
                            }.tag(lang)
                        }
                    }
                }
                
                Section("Optional Information") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    Picker("Priority", selection: $priority) {
                        Text("High").tag(1)
                        Text("Medium").tag(2)
                        Text("Low").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Set Target Date", isOn: $hasTargetDate)
                    
                    if hasTargetDate {
                        DatePicker("Target Date", selection: Binding(
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
        priority = item.priority
        targetDate = item.targetDate
        language = item.languageEnum
        hasTargetDate = item.targetDate != nil
    }
    
    private func saveItem() {
        let newItem = WatchlistItem(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            priority: priority,
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

