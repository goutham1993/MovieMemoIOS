//
//  NotificationManager.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/30/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Request notification permission
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // Schedule weekend watchlist reminder with custom time
    func scheduleWeekendReminder(at time: Date) {
        // Remove any existing weekend reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekend-watchlist-reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Weekend Movie Time! 🎬"
        content.body = "Your watchlist movies are waiting for you. Check it out!"
        content.sound = .default
        content.categoryIdentifier = "WATCHLIST_REMINDER"
        content.userInfo = ["targetTab": "watchlist"] // To open watchlist tab
        
        // Extract hour and minute from the provided time
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        // Schedule for Saturday at the specified time
        var dateComponents = DateComponents()
        dateComponents.weekday = 7 // Saturday (1 = Sunday, 7 = Saturday)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekend-watchlist-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekend reminder: \(error)")
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                print("Weekend reminder scheduled successfully for Saturdays at \(formatter.string(from: time))")
            }
        }
    }
    
    /// Schedule a recurring reminder on a specific weekday (1=Sun, 2=Mon ... 7=Sat) at the given hour.
    func scheduleDayReminder(weekday: Int, hour: Int = 19, minute: Int = 0) {
        let id = "day-reminder-\(weekday)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Movie Time! 🎬"
        content.body = "Did you watch a movie recently? Log it before you forget!"
        content.sound = .default
        content.categoryIdentifier = "MOVIE_LOG_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling day reminder: \(error)")
            }
        }
    }

    // Cancel all scheduled notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Check if notifications are authorized
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // Returns the raw authorization status for richer UI decisions
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
}

