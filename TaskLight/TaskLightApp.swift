//
//  TaskLightApp.swift
//  TaskLight
//
//  Created by Blake Lundstrom on 1/18/25.
//

import SwiftUI

// TaskLight v1.2
@main
struct TaskLightApp: App {
    @StateObject private var viewModel = TaskViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
