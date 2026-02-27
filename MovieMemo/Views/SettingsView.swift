//
//  SettingsView.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UserNotifications

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
    @State private var notificationsDeniedBySystem = false
    @State private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

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
                            notificationsDeniedBySystem = false
                            NotificationManager.shared.scheduleWeekendReminder(at: notificationTime)
                            let formatter = DateFormatter()
                            formatter.timeStyle = .short
                            successMessage = "Weekend reminders enabled! You'll get notified every Saturday at \(formatter.string(from: notificationTime))."
                            showingSuccessAlert = true
                        } else {
                            notificationsEnabled = false
                            notificationsDeniedBySystem = true
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

    private func triggerSuccessHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notifications
                Section("Notifications") {
                    if notificationsDeniedBySystem {
                        HStack(spacing: 8) {
                            Label("Notifications disabled in iOS Settings", systemImage: "bell.slash")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.footnote)
                        }
                    } else {
                        Toggle("Weekend Watchlist Reminders", isOn: notificationToggleBinding)

                        if notificationsEnabled {
                            DatePicker("Reminder Time",
                                       selection: $notificationTime,
                                       displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .onChange(of: notificationTime) { _, newTime in
                                    NotificationManager.shared.scheduleWeekendReminder(at: newTime)
                                    let formatter = DateFormatter()
                                    formatter.timeStyle = .short
                                    successMessage = "Reminder time updated to \(formatter.string(from: newTime))"
                                    showingSuccessAlert = true
                                }

                            Text("You'll receive a reminder every Saturday.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Data Management
                Section {
                    Button {
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
                                triggerSuccessHaptic()
                            } catch {
                                print("Export write error: \(error)")
                            }
                        }
                        showingExportSheet = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    .disabled(repository == nil)

                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                    .disabled(repository == nil)
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Your data stays on your device unless you export it.")
                }

                // MARK: - Danger Zone
                Section("Danger Zone") {
                    Button("Clear All Watched Movies", role: .destructive) {
                        showingClearWatchedAlert = true
                    }
                    .disabled(repository == nil)

                    Button("Clear All Watchlist Items", role: .destructive) {
                        showingClearWatchlistAlert = true
                    }
                    .disabled(repository == nil)
                }

                // MARK: - Premium
                Section("Premium") {
                    NavigationLink("Upgrade to Pro") {
                        VStack(spacing: 12) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.yellow)
                            Text("Pro Features")
                                .font(.title2.weight(.semibold))
                            Text("Coming Soon")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle("Upgrade to Pro")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(buildNumber)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }

                    Button {
                        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Rate MovieMemo", systemImage: "star")
                    }
                }

                // MARK: - Brand Footer
                Section {
                    VStack(spacing: 6) {
                        Text("MovieMemo")
                            .font(.footnote.weight(.medium))
                        Text("Built with care for mindful movie tracking.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExportSheet) {
                if let fileURL = exportFileURL {
                    ShareSheet(activityItems: [fileURL])
                } else {
                    VStack(spacing: 16) {
                        Text("Export Failed")
                            .font(.headline)
                        Text("Unable to create export file. Please try again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Close") {
                            showingExportSheet = false
                        }
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                DocumentPicker { url in
                    if let data = try? Data(contentsOf: url) {
                        if repository?.importData(data) == true {
                            triggerSuccessHaptic()
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
                    triggerSuccessHaptic()
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
                    triggerSuccessHaptic()
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
            if repository == nil {
                repository = MovieRepository(modelContext: modelContext)
            }

            NotificationManager.shared.getAuthorizationStatus { status in
                notificationsEnabled = (status == .authorized)
                notificationsDeniedBySystem = (status == .denied)
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

