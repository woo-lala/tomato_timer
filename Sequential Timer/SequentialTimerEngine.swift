import Foundation

struct StepTimelineItem: Equatable {
    let index: Int
    let name: String
    let durationSeconds: Int
    let startOffset: Int
    let endOffset: Int
}

struct StepProgress {
    let index: Int
    let remainingSeconds: Int
    let stepDurationSeconds: Int
    let isComplete: Bool
}

enum SequentialTimerEngine {
    static func buildTimeline(from steps: [RoutineStep]) -> [StepTimelineItem] {
        var items: [StepTimelineItem] = []
        var cursor = 0
        for (index, step) in steps.enumerated() {
            let duration = max(0, Int(step.durationSeconds))
            let item = StepTimelineItem(
                index: index,
                name: step.title ?? String(localized: "app.step.defaultName"),
                durationSeconds: duration,
                startOffset: cursor,
                endOffset: cursor + duration
            )
            items.append(item)
            cursor += duration
        }
        return items
    }

    static func resolveProgress(elapsedSeconds: Int, timeline: [StepTimelineItem]) -> StepProgress {
        guard !timeline.isEmpty else {
            return StepProgress(index: 0, remainingSeconds: 0, stepDurationSeconds: 0, isComplete: true)
        }
        let elapsed = max(0, elapsedSeconds)
        let total = timeline.last?.endOffset ?? 0
        if elapsed >= total {
            let last = timeline[timeline.count - 1]
            return StepProgress(index: last.index, remainingSeconds: 0, stepDurationSeconds: last.durationSeconds, isComplete: true)
        }
        for item in timeline {
            if elapsed < item.endOffset {
                return StepProgress(
                    index: item.index,
                    remainingSeconds: max(item.endOffset - elapsed, 0),
                    stepDurationSeconds: item.durationSeconds,
                    isComplete: false
                )
            }
        }
        let last = timeline[timeline.count - 1]
        return StepProgress(index: last.index, remainingSeconds: 0, stepDurationSeconds: last.durationSeconds, isComplete: true)
    }
}
