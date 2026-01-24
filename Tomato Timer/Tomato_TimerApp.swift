//
//  Tomato_TimerApp.swift
//  Tomato Timer
//
//  Created by woolala on 1/17/26.
//

import SwiftUI
import CoreData

@main
struct Tomato_TimerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
