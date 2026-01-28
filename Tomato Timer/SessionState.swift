import Foundation

struct SessionState: Codable, Equatable {
    var sessionId: UUID
    var routineId: UUID
    var startAt: Date
    var isPaused: Bool
    var pausedAt: Date?
    var accumulatedPausedSeconds: Int
    var currentStepIndex: Int
    var notificationMode: NotificationMode
    var notificationPatternId: String
    var scheduledNotificationIds: [String]

    func activeElapsedSeconds(now: Date = Date()) -> Int {
        if isPaused, let pausedAt {
            let elapsed = Int(pausedAt.timeIntervalSince(startAt)) - accumulatedPausedSeconds
            return max(elapsed, 0)
        }
        let elapsed = Int(now.timeIntervalSince(startAt)) - accumulatedPausedSeconds
        return max(elapsed, 0)
    }

    init(
        sessionId: UUID,
        routineId: UUID,
        startAt: Date,
        isPaused: Bool,
        pausedAt: Date?,
        accumulatedPausedSeconds: Int,
        currentStepIndex: Int,
        notificationMode: NotificationMode,
        notificationPatternId: String,
        scheduledNotificationIds: [String]
    ) {
        self.sessionId = sessionId
        self.routineId = routineId
        self.startAt = startAt
        self.isPaused = isPaused
        self.pausedAt = pausedAt
        self.accumulatedPausedSeconds = accumulatedPausedSeconds
        self.currentStepIndex = currentStepIndex
        self.notificationMode = notificationMode
        self.notificationPatternId = notificationPatternId
        self.scheduledNotificationIds = scheduledNotificationIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId) ?? UUID()
        routineId = try container.decodeIfPresent(UUID.self, forKey: .routineId) ?? UUID()
        startAt = try container.decodeIfPresent(Date.self, forKey: .startAt) ?? Date()
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
        accumulatedPausedSeconds = try container.decodeIfPresent(Int.self, forKey: .accumulatedPausedSeconds) ?? 0
        currentStepIndex = try container.decodeIfPresent(Int.self, forKey: .currentStepIndex) ?? 0
        notificationMode = try container.decodeIfPresent(NotificationMode.self, forKey: .notificationMode) ?? .sound
        notificationPatternId = try container.decodeIfPresent(String.self, forKey: .notificationPatternId) ?? "basic"
        scheduledNotificationIds = try container.decodeIfPresent([String].self, forKey: .scheduledNotificationIds) ?? []
    }
}

enum SessionStore {
    private enum Keys {
        static let state = "seqtimer.sessionState.v1"
    }

    static func load() -> SessionState? {
        guard let data = UserDefaults.standard.data(forKey: Keys.state) else { return nil }
        return try? JSONDecoder().decode(SessionState.self, from: data)
    }

    static func save(_ state: SessionState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Keys.state)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: Keys.state)
    }
}

func notificationIdentifier(sessionId: UUID, stepIndex: Int) -> String {
    "seqtimer.\(sessionId.uuidString).step.\(stepIndex)"
}

func completionNotificationIdentifier(sessionId: UUID) -> String {
    "seqtimer.\(sessionId.uuidString).complete"
}
