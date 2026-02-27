//
//  SettingsView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var repository: MovieRepository?
    @State private var showingClearWatchedAlert = false
    @State private var showingClearWatchlistAlert = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var exportFileURL: URL?
    @State private var notificationsEnabled = false
    @State private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    
    // Custom binding so the action logic only fires on explicit user interaction,
    // not when onAppear silently restores the toggle state from the system.
    private var notificationToggleBinding: Binding<Bool> {
        Binding(
            get: { notificationsEnabled },
            set: { newValue in
                notificationsEnabled = newValue
                if newValue {
                    NotificationManager.shared.requestAuthorization { granted in
                        if granted {
                            NotificationManager.shared.scheduleWeekendReminder(at: notificationTime)
                            let formatter = DateFormatter()
                            formatter.timeStyle = .short
                            successMessage = "Weekend reminders enabled! You'll get notified every Saturday at \(formatter.string(from: notificationTime))."
                            showingSuccessAlert = true
                        } else {
                            notificationsEnabled = false
                            successMessage = "Please enable notifications in Settings to receive reminders."
                            showingSuccessAlert = true
                        }
                    }
                } else {
                    NotificationManager.shared.cancelAllNotifications()
                    successMessage = "Weekend reminders disabled."
                    showingSuccessAlert = true
                }
            }
        )
    }

    var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    Toggle("Weekend Watchlist Reminders", isOn: notificationToggleBinding)
                    
                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .onChange(of: notificationTime) { _, newTime in
                                // Update the notification schedule when time changes
                                NotificationManager.shared.scheduleWeekendReminder(at: newTime)
                                let formatter = DateFormatter()
                                formatter.timeStyle = .short
                                successMessage = "Reminder time updated to \(formatter.string(from: newTime))"
                                showingSuccessAlert = true
                            }
                        
                        Text("You'll receive a reminder every Saturday")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        exportFileURL = nil
                        if let data = repository?.exportData() {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyyMMdd_HHmmss"
                            let timestamp = formatter.string(from: Date())
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent("MovieMemo_Export_\(timestamp).json")
                            do {
                                try data.write(to: tempURL)
                                exportFileURL = tempURL
                            } catch {
                                print("Export write error: \(error)")
                            }
                        }
                        showingExportSheet = true
                    }
                    .foregroundColor(.blue)
                    .disabled(repository == nil)
                    
                    Button("Import Data") {
                        showingImportSheet = true
                    }
                    .foregroundColor(.blue)
                    .disabled(repository == nil)
                }
                
                Section("Clear Data") {
                    Button("Clear All Watched Movies") {
                        showingClearWatchedAlert = true
                    }
                    .foregroundColor(.red)
                    .disabled(repository == nil)
                    
                    Button("Clear All Watchlist Items") {
                        showingClearWatchlistAlert = true
                    }
                    .foregroundColor(.red)
                    .disabled(repository == nil)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExportSheet) {
                if let fileURL = exportFileURL {
                    ShareSheet(activityItems: [fileURL])
                } else {
                    VStack {
                        Text("Export Failed")
                            .font(.headline)
                        Text("Unable to create export file. Please try again.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Close") {
                            showingExportSheet = false
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                DocumentPicker { url in
                    if let data = try? Data(contentsOf: url) {
                        if repository?.importData(data) == true {
                            successMessage = "Data imported successfully!"
                            showingSuccessAlert = true
                        } else {
                            successMessage = "Failed to import data. Please check the file format."
                            showingSuccessAlert = true
                        }
                    }
                }
            }
            .alert("Clear Watched Movies", isPresented: $showingClearWatchedAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    repository?.clearAllWatchedEntries()
                    successMessage = "All watched movies have been cleared."
                    showingSuccessAlert = true
                }
            } message: {
                Text("This will permanently delete all watched movies. This action cannot be undone.")
            }
            .alert("Clear Watchlist", isPresented: $showingClearWatchlistAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    repository?.clearAllWatchlistItems()
                    successMessage = "All watchlist items have been cleared."
                    showingSuccessAlert = true
                }
            } message: {
                Text("This will permanently delete all watchlist items. This action cannot be undone.")
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text(successMessage)
            }
        }
        .onAppear {
            // Initialize repository with the environment's modelContext
            if repository == nil {
                repository = MovieRepository(modelContext: modelContext)
            }
            
            // Check notification authorization status
            NotificationManager.shared.checkAuthorizationStatus { isAuthorized in
                notificationsEnabled = isAuthorized
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WatchedEntry.self, WatchlistItem.self, Genre.self], inMemory: true)
}

