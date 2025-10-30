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
    @State private var exportData: Data?
    @State private var notificationsEnabled = false
    
    private var exportFileURL: URL? {
        guard let data = exportData else { return nil }
        let fileName = "MovieMemo_Export_\(Date().timeIntervalSince1970).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    Toggle("Weekend Watchlist Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                NotificationManager.shared.requestAuthorization { granted in
                                    if granted {
                                        NotificationManager.shared.scheduleWeekendReminder()
                                        successMessage = "Weekend reminders enabled! You'll get notified every Saturday at 10:00 AM."
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
                    
                    if notificationsEnabled {
                        Text("You'll receive a reminder every Saturday at 10:00 AM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        exportData = repository?.exportData()
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

