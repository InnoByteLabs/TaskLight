//
//  TaskLightApp.swift
//  TaskLight
//
//  Created by Blake Lundstrom on 1/18/25.
//

import SwiftUI
import SwiftData

@main
struct TaskLightApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: Item.self, configurations: config)
        } catch {
            fatalError("Could not configure ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
