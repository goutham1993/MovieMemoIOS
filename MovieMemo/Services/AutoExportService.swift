//
//  AutoExportService.swift
//  MovieMemo
//

import Foundation
import SwiftData

enum AutoExportService {
    /// Must match `@AppStorage` key in Settings.
    static let enabledUserDefaultsKey = "autoDataExportEnabled"

    private static let lastYearMonthKey = "lastAutoExportYearMonth"
    private static let exportsFolderName = "MovieMemoExports"

    private static let yearMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static let exportTimestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()

    @MainActor
    static func performIfNeeded(modelContext: ModelContext) {
        guard UserDefaults.standard.bool(forKey: enabledUserDefaultsKey) else { return }

        let now = Date()
        let currentYM = yearMonthFormatter.string(from: now)
        if UserDefaults.standard.string(forKey: lastYearMonthKey) == currentYM { return }

        let repository = MovieRepository(modelContext: modelContext)
        guard let data = repository.exportData() else {
            Log.error("AutoExport: exportData returned nil")
            return
        }

        do {
            let dir = try exportsDirectoryURL()
            let timestamp = exportTimestampFormatter.string(from: now)
            let fileURL = dir.appendingPathComponent("MovieMemo_Export_\(timestamp).json")
            try data.write(to: fileURL, options: .atomic)
            UserDefaults.standard.set(currentYM, forKey: lastYearMonthKey)
            AnalyticsService.shared.track(.autoExportCompleted)
        } catch {
            Log.error("AutoExport: write error: \(String(describing: error))")
        }
    }

    private static func exportsDirectoryURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "AutoExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing documents directory"])
        }
        let dir = docs.appendingPathComponent(exportsFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
