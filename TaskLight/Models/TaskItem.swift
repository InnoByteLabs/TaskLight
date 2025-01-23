import CloudKit

struct TaskItem: Identifiable {
    enum Priority: Int, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
        
        var title: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
    
    let id: String
    var title: String
    var isCompleted: Bool
    var notes: String?
    var priority: Priority
    var dueDate: Date?
    var recordID: CKRecord.ID?
    var isDeleted: Bool
    var deletedDate: Date?
    var parentTaskID: String?
    var hasSubtasks: Bool
    var isExpanded: Bool
    
    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        notes: String? = nil,
        priority: Priority = .low,
        dueDate: Date? = nil,
        recordID: CKRecord.ID? = nil,
        isDeleted: Bool = false,
        deletedDate: Date? = nil,
        parentTaskID: String? = nil,
        hasSubtasks: Bool = false,
        isExpanded: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.notes = notes
        self.priority = priority
        self.dueDate = dueDate
        self.recordID = recordID
        self.isDeleted = isDeleted
        self.deletedDate = deletedDate
        self.parentTaskID = parentTaskID
        self.hasSubtasks = hasSubtasks
        self.isExpanded = isExpanded
    }
}

// MARK: - CloudKit Conversion
extension TaskItem {
    init?(from record: CKRecord) {
        guard let title = record[CloudKitManager.RecordKey.title] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.title = title
        self.isCompleted = (record[CloudKitManager.RecordKey.isCompleted] as? Int64 ?? 0) == 1
        if let notes = record[CloudKitManager.RecordKey.notes] as? String, !notes.isEmpty {
            self.notes = notes
        } else {
            self.notes = nil
        }
        self.priority = Priority(rawValue: Int(record[CloudKitManager.RecordKey.priority] as? Int64 ?? 1)) ?? .medium
        self.dueDate = record[CloudKitManager.RecordKey.dueDate] as? Date
        self.recordID = record.recordID
        self.isDeleted = (record[CloudKitManager.RecordKey.isDeleted] as? Int64 ?? 0) == 1
        self.deletedDate = record[CloudKitManager.RecordKey.deletedDate] as? Date
        self.parentTaskID = record[CloudKitManager.RecordKey.parentTaskID] as? String
        self.hasSubtasks = (record[CloudKitManager.RecordKey.hasSubtasks] as? Int64 ?? 0) == 1
        self.isExpanded = false  // Always start collapsed
    }
    
    func toCKRecord() -> CKRecord {
        if let existingRecordID = recordID {
            // Use existing record ID for updates
            let record = CKRecord(recordType: "Task", recordID: existingRecordID)
            updateRecord(record)
            return record
        } else {
            // Create new record with generated ID
            let newRecordID = CKRecord.ID(recordName: UUID().uuidString)
            let record = CKRecord(recordType: "Task", recordID: newRecordID)
            updateRecord(record)
            return record
        }
    }
    
    private func updateRecord(_ record: CKRecord) {
        record[CloudKitManager.RecordKey.title] = title
        record[CloudKitManager.RecordKey.isCompleted] = isCompleted ? 1 : 0
        record[CloudKitManager.RecordKey.notes] = notes
        record[CloudKitManager.RecordKey.priority] = Int64(priority.rawValue)
        record[CloudKitManager.RecordKey.dueDate] = dueDate
        record[CloudKitManager.RecordKey.createdAt] = Date()
        record[CloudKitManager.RecordKey.modifiedAt] = Date()
        record[CloudKitManager.RecordKey.isDeleted] = isDeleted ? 1 : 0
        record[CloudKitManager.RecordKey.deletedDate] = deletedDate
        record[CloudKitManager.RecordKey.parentTaskID] = parentTaskID
        record[CloudKitManager.RecordKey.hasSubtasks] = hasSubtasks ? 1 : 0
    }
}