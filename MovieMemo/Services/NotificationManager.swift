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
    
    // Schedule weekend watchlist reminder
    func scheduleWeekendReminder() {
        // Remove any existing weekend reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekend-watchlist-reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Weekend Movie Time! 🎬"
        content.body = "Your watchlist movies are waiting for you. Check it out!"
        content.sound = .default
        content.categoryIdentifier = "WATCHLIST_REMINDER"
        content.userInfo = ["targetTab": "watchlist"] // To open watchlist tab
        
        // Schedule for Saturday at 10:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 7 // Saturday (1 = Sunday, 7 = Saturday)
        dateComponents.hour = 10
        dateComponents.minute = 0
        
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
                print("Weekend reminder scheduled successfully for Saturdays at 10:00 AM")
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
}

