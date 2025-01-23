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
    
    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        notes: String? = nil,
        priority: Priority = .low,
        dueDate: Date? = nil,
        recordID: CKRecord.ID? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.notes = notes
        self.priority = priority
        self.dueDate = dueDate
        self.recordID = recordID
    }
}

// MARK: - CloudKit Conversion
extension TaskItem {
    init?(from record: CKRecord) {
        guard let title = record[CloudKitManager.RecordKey.title] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.title = title
        self.isCompleted = (record[CloudKitManager.RecordKey.isCompleted] as? Int64 ?? 0) == 1
        self.notes = record[CloudKitManager.RecordKey.notes] as? String
        self.priority = Priority(rawValue: Int(record[CloudKitManager.RecordKey.priority] as? Int64 ?? 1)) ?? .medium
        self.dueDate = record[CloudKitManager.RecordKey.dueDate] as? Date
        self.recordID = record.recordID
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
    }
}