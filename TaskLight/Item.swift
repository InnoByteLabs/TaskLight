//
//  Item.swift
//  TaskLight
//
//  Created by Blake Lundstrom on 1/18/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String
    var timestamp: Date
    var isCompleted: Bool
    var isShared: Bool
    var assignedTo: String?
    @Relationship(deleteRule: .cascade) var subTasks: [Item] = []
    var parentTask: Item?
    
    init(title: String = "", timestamp: Date = .now) {
        self.title = title
        self.timestamp = timestamp
        self.isCompleted = false
        self.isShared = false
        self.assignedTo = nil
    }
}
