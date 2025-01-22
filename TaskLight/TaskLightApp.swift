//
//  TaskLightApp.swift
//  TaskLight
//
//  Created by Blake Lundstrom on 1/18/25.
//

import SwiftUI
import SwiftData

// TaskLight v1.2
@main
struct TaskLightApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([Item.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
