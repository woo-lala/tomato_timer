//
//  Tomato_TimerApp.swift
//  Sequential Timer
//
//  Created by woolala on 1/17/26.
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct Tomato_TimerApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var languageStore = LanguageStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeStore)
                .environmentObject(languageStore)
                .modifier(ThemeProvider(themeStore: themeStore))
                .preferredColorScheme(themeStore.preferredColorScheme)
                .environment(\.locale, languageStore.locale ?? Locale.autoupdatingCurrent)
                .id(languageStore.selection)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
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
