import Foundation
import CloudKit

struct TaskItem: Identifiable {
    let id: String
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    var notes: String?
    var createdAt: Date
    var modifiedAt: Date
    var recordID: CKRecord.ID?
    
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
    
    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        notes: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        recordID: CKRecord.ID? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.recordID = recordID
    }
}

// MARK: - CloudKit Conversion
extension TaskItem {
    init?(from record: CKRecord) {
        guard let title = record[CloudKitManager.RecordKey.title] as? String else {
            return nil
        }
        
        let recordName = record.recordID.recordName
        self.id = recordName
        self.title = title
        self.isCompleted = (record[CloudKitManager.RecordKey.isCompleted] as? Int64 ?? 0) == 1
        self.dueDate = record[CloudKitManager.RecordKey.dueDate] as? Date
        self.priority = Priority(rawValue: record[CloudKitManager.RecordKey.priority] as? Int ?? 1) ?? .medium
        self.notes = record[CloudKitManager.RecordKey.notes] as? String
        self.createdAt = record[CloudKitManager.RecordKey.createdAt] as? Date ?? Date()
        self.modifiedAt = record[CloudKitManager.RecordKey.modifiedAt] as? Date ?? Date()
        self.recordID = record.recordID
    }
    
    func toCKRecord() -> CKRecord {
        // Use existing recordID if available, otherwise create new one
        let recordID = self.recordID ?? CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: CloudKitManager.RecordType.task, recordID: recordID)
        
        record[CloudKitManager.RecordKey.title] = title
        record[CloudKitManager.RecordKey.isCompleted] = isCompleted ? 1 : 0
        record[CloudKitManager.RecordKey.dueDate] = dueDate
        record[CloudKitManager.RecordKey.priority] = priority.rawValue
        record[CloudKitManager.RecordKey.notes] = notes
        record[CloudKitManager.RecordKey.createdAt] = createdAt
        record[CloudKitManager.RecordKey.modifiedAt] = modifiedAt
        
        return record
    }
} 