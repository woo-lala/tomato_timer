import Foundation
import CoreData

#if canImport(CryptoKit)
import CryptoKit
#endif

enum SyncDateUtils {
    static func kstDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func todayKSTString(now: Date = Date()) -> String {
        kstDateString(from: now)
    }
}

enum RoutineDTOBuilder {
    static func build(from routine: Routine) -> RoutineDTO? {
        guard let routineId = routine.routineId?.uuidString else { return nil }
        let name = routine.name ?? ""
        let createdAt = routine.createdAt ?? Date()
        let updatedAt = routine.updatedAt ?? createdAt
        let isArchived = routine.isArchived
        let isTemplate = routine.isTemplate
        let keepScreenOn = routine.keepScreenOn

        let stepsSet = routine.steps as? Set<RoutineStep> ?? []
        let steps = stepsSet
            .sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
            .compactMap { step -> RoutineStepDTO? in
                guard let stepId = step.stepId?.uuidString else { return nil }
                let title = step.title ?? ""
                let duration = max(0, Int(step.durationSeconds))
                return RoutineStepDTO(stepId: stepId, order: Int(step.order), title: title, durationSeconds: duration)
            }

        return RoutineDTO(
            routineId: routineId,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            isTemplate: isTemplate,
            keepScreenOn: keepScreenOn,
            steps: steps,
            schemaVersion: SyncConstants.schemaVersion
        )
    }
}

enum RoutinePayloadHasher {
    static func hash(for routine: Routine) -> String? {
        guard let routineId = routine.routineId?.uuidString else { return nil }
        let name = routine.name ?? ""
        let updatedAt = routine.updatedAt?.timeIntervalSince1970 ?? 0
        let stepsSet = routine.steps as? Set<RoutineStep> ?? []
        let steps = stepsSet
            .sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
            .map { step in
                let stepId = step.stepId?.uuidString ?? ""
                let title = step.title ?? ""
                return "\(stepId)|\(step.order)|\(step.durationSeconds)|\(title)"
            }
            .joined(separator: ";")

        let raw = "\(routineId)|\(name)|\(updatedAt)|\(steps)"
        return sha256(raw)
    }

    private static func sha256(_ input: String) -> String? {
        #if canImport(CryptoKit)
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        return nil
        #endif
    }
}

enum SessionSummaryBuilder {
    static func build(from session: Session) -> SessionSummaryDTO? {
        guard let sessionId = session.sessionId?.uuidString else { return nil }
        guard let routineId = session.routineId?.uuidString else { return nil }
        guard let startedAt = session.startedAt else { return nil }
        guard let endedAt = session.endedAt else { return nil }
        guard let status = session.status else { return nil }
        guard status == SessionStatus.completed.rawValue || status == SessionStatus.abandoned.rawValue else { return nil }

        let pauseCount = Int(session.pauseCount)
        let plannedStepCount = routineStepCount(from: session)
        let completedStepCount = resolveCompletedStepCount(from: session, planned: plannedStepCount, status: status)
        let actualDurationSeconds = max(0, Int(endedAt.timeIntervalSince(startedAt)))
        let date = SyncDateUtils.kstDateString(from: startedAt)
        let patternKey = buildPatternKey(from: session)

        return SessionSummaryDTO(
            sessionId: sessionId,
            routineId: routineId,
            startedAt: startedAt,
            endedAt: endedAt,
            status: status,
            pauseCount: pauseCount,
            plannedStepCount: plannedStepCount,
            completedStepCount: completedStepCount,
            actualDurationSeconds: actualDurationSeconds,
            date: date,
            patternKey: patternKey,
            createdAt: Date(),
            schemaVersion: SyncConstants.schemaVersion
        )
    }

    private static func routineStepCount(from session: Session) -> Int {
        let routineSteps = session.routine?.steps as? Set<RoutineStep> ?? []
        return routineSteps.count
    }

    private static func resolveCompletedStepCount(from session: Session, planned: Int, status: String) -> Int {
        if status == SessionStatus.completed.rawValue {
            return planned
        }
        let steps = session.steps as? Set<SessionStep> ?? []
        if steps.isEmpty {
            return 0
        }
        return steps.filter { $0.isCompleted }.count
    }

    private static func buildPatternKey(from session: Session) -> String {
        let routineSteps = session.routine?.steps as? Set<RoutineStep> ?? []
        let sorted = routineSteps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
        let parts = sorted.map { step -> String in
            let minutes = max(0, Int(step.durationSeconds / 60))
            return "S\(minutes)"
        }
        return parts.joined(separator: "-")
    }
}
