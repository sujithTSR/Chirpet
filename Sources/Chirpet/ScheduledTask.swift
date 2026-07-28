import Foundation

public enum TaskRecurrence: Equatable {
    case oneTime
    case repetitive(intervalSeconds: TimeInterval)
    
    public var description: String {
        switch self {
        case .oneTime:
            return "One-Time"
        case .repetitive(let seconds):
            let mins = Int(seconds / 60)
            if mins >= 60 {
                let hrs = mins / 60
                return "Every \(hrs)h"
            }
            return "Every \(mins)m"
        }
    }
}

public struct ScheduledTask: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var recurrence: TaskRecurrence
    public var dueDate: Date
    public var isEnabled: Bool
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        recurrence: TaskRecurrence,
        dueDate: Date,
        isEnabled: Bool = true,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.recurrence = recurrence
        self.dueDate = dueDate
        self.isEnabled = isEnabled
        self.isCompleted = isCompleted
    }
    
    public var timeRemainingString: String {
        let remaining = dueDate.timeIntervalSinceNow
        if remaining <= 0 {
            return "Due now!"
        }
        let mins = Int(remaining / 60)
        let secs = Int(remaining) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}
