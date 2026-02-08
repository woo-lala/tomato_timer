import Foundation

struct RoutineStepDTO: Equatable {
    let stepId: String
    let order: Int
    let title: String
    let durationSeconds: Int
}

struct RoutineDTO: Equatable {
    let routineId: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool
    let isTemplate: Bool
    let keepScreenOn: Bool
    let steps: [RoutineStepDTO]
    let schemaVersion: Int
}

struct SessionSummaryDTO: Equatable {
    let sessionId: String
    let routineId: String
    let startedAt: Date
    let endedAt: Date
    let status: String
    let pauseCount: Int
    let plannedStepCount: Int
    let completedStepCount: Int
    let actualDurationSeconds: Int
    let date: String
    let patternKey: String
    let createdAt: Date
    let schemaVersion: Int
}

enum UploadQueueItemType: String {
    case routine
    case session
}

enum UploadQueueItemStatus: String {
    case pending
    case failed
}

enum SessionStatus: String {
    case running = "RUNNING"
    case paused = "PAUSED"
    case completed = "COMPLETED"
    case abandoned = "ABANDONED"
}

enum SyncConstants {
    static let schemaVersion = 1
}
