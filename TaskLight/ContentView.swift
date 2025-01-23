//
//  ContentView.swift
//  TaskLight
//
//  Created by Blake Lundstrom on 1/18/25.
//

import SwiftUI

/*
 TaskLight v1.0
 A task management app with support for sub-tasks and task assignment
 
 Core Features:
 - Main tasks and sub-tasks
 - Task assignment via email
 - Independent task completion
 - Swipe actions for task management
 - Visual hierarchy with indented sub-tasks
 - Data persistence using SwiftData
 
 Created: March 2024
*/

struct ContentView: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        NavigationView {
            TaskListView(viewModel: viewModel)
        }
        .task {
            await viewModel.checkCloudKitAvailability()
            await viewModel.fetchTasks()
        }
        .alert("Error", isPresented: $viewModel.isShowingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

/*
 Data Model v1.0:
 - Item: Represents both main tasks and sub-tasks
 - Properties:
   - title: String
   - timestamp: Date
   - isCompleted: Bool
   - isShared: Bool
   - assignedTo: String?
   - subTasks: [Item]
   - parentTask: Item?
*/

/*
 Planned for v1.1:
 - [ ] Task due dates
 - [ ] Task priorities
 - [ ] Task categories/tags
 - [ ] Task notes/descriptions
 - [ ] Task sharing improvements
 - [ ] Search functionality
 - [ ] Filter/sort options
*/

#Preview {
    ContentView(viewModel: TaskViewModel())
}
