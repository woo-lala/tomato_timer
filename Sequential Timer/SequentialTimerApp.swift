//
//  SequentialTimerApp.swift
//  Sequential Timer
//
//  Created by woolala on 1/17/26.
//

import SwiftUI
import CoreData
import UserNotifications
import Foundation
import FirebaseCore

@main
struct SequentialTimerApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var themeStore = ThemeStore()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeStore)
                .modifier(ThemeProvider(themeStore: themeStore))
                .preferredColorScheme(themeStore.preferredColorScheme)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        SyncManager.shared.handleAppBecameActive()
                    }
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        UserDefaults.standard.set(true, forKey: "seqtimer.didOpenFromNotification")
        SessionStore.clearScheduledNotifications()
        completionHandler()
    }
}
