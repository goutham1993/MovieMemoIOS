//
//  AppDelegate.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/30/25.
//

import UIKit
import UserNotifications
import PostHog

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // PostHog analytics (disabled if config is missing)
        if let apiKey = AppConfig.postHogAPIKey, let host = AppConfig.postHogHost {
            let config = PostHogConfig(apiKey: apiKey, host: host)
            config.captureScreenViews = false
            config.captureApplicationLifecycleEvents = false
            PostHogSDK.shared.setup(config)
            AnalyticsService.shared.track(.appOpened)
        } else {
            Log.error("PostHog config missing; analytics disabled.")
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a watchlist reminder
        if let targetTab = userInfo["targetTab"] as? String, targetTab == "watchlist" {
            // Post notification to switch to watchlist tab
            NotificationCenter.default.post(name: NSNotification.Name("SwitchToWatchlist"), object: nil)
        }
        
        completionHandler()
    }
}

