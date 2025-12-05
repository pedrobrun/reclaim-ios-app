//
//  NotificationManager.swift
//  Reclaim
//
//  Manages local and remote notifications
//

import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    private let apiClient = APIClient.shared
    
    @Published var isAuthorized = false
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Setup
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            Task { @MainActor in
                self?.isAuthorized = granted
                
                if granted {
                    print("✅ Notification permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                    self?.scheduleDailyCheckIn()
                } else if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                } else {
                    print("❌ Notification permission denied")
                }
            }
        }
    }
    
    // MARK: - Remote Notifications
    
    func registerDeviceToken(_ tokenData: Data) {
        let tokenParts = tokenData.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        print("📱 Device Token: \(token)")
        
        Task {
            do {
                let request = CreateDeviceRequest(token: token, type: "ios")
                try await apiClient.request(.registerDevice, body: request)
                print("✅ Device registered with backend")
            } catch {
                print("❌ Failed to register device: \(error)")
            }
        }
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle remote notification payload
        print("📩 Received remote notification: \(userInfo)")
    }
    
    // MARK: - Local Notifications
    
    func scheduleDailyCheckIn() {
        // Remove existing requests first to avoid duplicates
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "How are you feeling today? Log your progress to keep your streak alive!"
        content.sound = .default
        
        // Schedule for 8:00 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily-checkin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily check-in: \(error)")
            } else {
                print("✅ Scheduled daily check-in for 8:00 PM")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and sound even if app is open
        completionHandler([.banner, .sound, .list])
    }
    
    // Handle notification response (user tapped)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleRemoteNotification(userInfo)
        completionHandler()
    }
}

