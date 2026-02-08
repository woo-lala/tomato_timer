
import SwiftUI
import AVFoundation
import CoreHaptics
import Combine
import CoreData
import UserNotifications

struct TimerRunningView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.themePalette) private var theme
    @Environment(\.locale) private var locale
    
    let routine: Routine
    let initialConfiguration: NotificationConfiguration?
    let initialStepTransitionMode: StepTransitionMode
    let forceNewSession: Bool
    @State private var configuration: NotificationConfiguration = .default
    @State private var showAlarmSettings: Bool = false
    
    // Timer State
    @State private var currentStepIndex: Int = 0
    @State private var remainingSeconds: Int = 0
    @State private var isScreenOn: Bool
    @State private var showFinishAlert: Bool = false
    @State private var sessionState: SessionState?
    @State private var lastSyncedStepIndex: Int?
    @State private var hasSyncedOnce: Bool = false
    @State private var showManualNextAlert: Bool = false
    @State private var hasShownManualAlertForStep: Int?
    @State private var showAutoAdvanceAlert: Bool = false
    @AppStorage("seqtimer.didOpenFromNotification") private var didOpenFromNotification: Bool = false
    @State private var manualAlertNotificationTimers: [DispatchWorkItem] = []
    private let backgroundRepeatCount = 1
    private let backgroundRepeatInterval: TimeInterval = 2.2
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(routine: Routine, initialConfiguration: NotificationConfiguration?, initialStepTransitionMode: StepTransitionMode = .manual, forceNewSession: Bool = false) {
        self.routine = routine
        self.initialConfiguration = initialConfiguration
        self.initialStepTransitionMode = initialStepTransitionMode
        self.forceNewSession = forceNewSession
        _isScreenOn = State(initialValue: routine.keepScreenOn)
    }
    
    var sortedSteps: [RoutineStep] {
        let steps = routine.steps as? Set<RoutineStep> ?? []
        return steps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
    }
    
    var timeline: [StepTimelineItem] {
        SequentialTimerEngine.buildTimeline(from: sortedSteps)
    }
    
    var timeString: String {
        formatTime(remainingSeconds)
    }
    
    var currentStepName: String {
        guard currentStepIndex < timeline.count else { return String(localized: "timer.running.currentStep.default", locale: locale) }
        return timeline[currentStepIndex].name
    }
    
    var nextStepInfo: String {
        let nextIndex = currentStepIndex + 1
        guard nextIndex < timeline.count else { return String(localized: "timer.running.lastStep") }
        let next = timeline[nextIndex]
        let minutes = next.durationSeconds / 60
        let seconds = next.durationSeconds % 60
        if minutes > 0 && seconds > 0 {
            return String(format: String(localized: "timer.running.nextStep.full", locale: locale), next.name, minutes, seconds)
        }
        if minutes > 0 {
            return String(format: String(localized: "timer.running.nextStep.minutes", locale: locale), next.name, minutes)
        }
        return String(format: String(localized: "timer.running.nextStep.seconds", locale: locale), next.name, seconds)
    }

    var displayStepIndex: Int {
        guard !sortedSteps.isEmpty else { return 0 }
        return min(currentStepIndex + 1, sortedSteps.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Central Card
                    VStack(spacing: 20) {
                        // Step Badge
                        Text("\(displayStepIndex)/\(sortedSteps.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.accent)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(theme.accent.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.top, 20)
                        
                        // Current Step Name
                        Text(currentStepName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(theme.textPrimary)
                        
                        // Timer Display
                        Text(timeString)
                            .font(.system(size: 80, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.accent)
                            .padding(.vertical, 10)
                            .minimumScaleFactor(0.5)
                        
                        // Next Step Info
                        Text(nextStepInfo)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                            .padding(.bottom, 10)
                    }
                    .padding(AppSpacing.mediumPlus)
                    .frame(maxWidth: .infinity)
                    .background(theme.surface)
                    .cornerRadius(30)
                    .shadow(color: theme.shadow, radius: 24, x: 0, y: 12)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .offset(y: -32)
                    
                    // Options below card
                    VStack(spacing: 20) {
                        Toggle("timer.running.keepScreenOn", isOn: $isScreenOn)
                            .toggleStyle(SwitchToggleStyle(tint: theme.accent))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                        
                        Button(action: {
                            showAlarmSettings = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(theme.textSecondary)
                                Text(String(format: String(localized: "timer.running.executionMode", locale: locale), transitionDisplayText, configDisplayText))
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.textSecondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    
                    Spacer()
                    
                    // Bottom Controls
                    HStack(spacing: 40) {
                        // Stop Button
                        VStack(spacing: 8) {
                            Button(action: {
                                stopSession()
                                dismiss()
                            }) {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Image(systemName: "stop.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.red)
                                    )
                            }
                            Text("common.stop")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        // Pause/Play Button
                        VStack(spacing: 8) {
                            Button(action: {
                                handlePrimaryAction()
                            }) {
                                Circle()
                                    .fill(theme.accent)
                                    .frame(width: 72, height: 72)
                                    .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        Image(systemName: primaryActionIconName)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                            .offset(x: primaryActionIconName == "play.fill" ? 2 : 0)
                                    )
                            }
                            Text(primaryActionLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        // Skip Button
                        VStack(spacing: 8) {
                            Button(action: {
                                skipToNextStep()
                            }) {
                                Circle()
                                    .fill(theme.background)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(theme.textSecondary)
                                    )
                            }
                            Text("common.skip")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(routine.name ?? String(localized: "app.routine.defaultName", locale: locale))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(theme.textPrimary)
                                .font(.system(size: 18, weight: .medium))
                    }
            }
        }
        .alert("timer.running.finishAlert.title", isPresented: $showFinishAlert) {
            Button("common.confirm", action: {
                dismiss()
            })
        } message: {
            Text("timer.running.finishAlert.message")
        }
        .alert(manualAlertTitle, isPresented: $showManualNextAlert) {
            Button(manualAlertPrimaryLabel, action: {
                startNextStepFromManualAlert()
            })
            if manualAlertShowsLaterButton {
                Button("common.later", role: .cancel) {
                    handleManualAlertLater()
                }
            }
        } message: {
            Text(manualAlertMessage)
        }
        .alert("timer.running.autoAdvanceAlert.title", isPresented: $showAutoAdvanceAlert) {
            Button("common.confirm", role: .cancel) {}
        } message: {
            Text("timer.running.autoAdvanceAlert.message")
        }
            .sheet(isPresented: $showAlarmSettings) {
                NotificationModeSheet(routine: routine, onStart: { selectedRoutine, config, transitionMode in
                    configuration = config
                    if var state = sessionState {
                        applyConfiguration(config, to: &state)
                        state.stepTransitionMode = transitionMode
                        sessionState = state
                        SessionStore.save(state)
                        if state.isPaused == false {
                            scheduleNotifications(for: state)
                        }
                    }
                    showAlarmSettings = false
                })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(timer) { _ in
            guard sessionState?.isPaused == false else { return }
            syncDisplay(now: Date())
        }
        .onAppear {
            if let initial = initialConfiguration {
                configuration = initial
            } else {
                loadLastNotificationConfiguration()
            }
            requestNotificationAuthorization()
            loadOrStartSession()
            syncDisplay(now: Date())
            // 화면 켜짐 유지 설정
            UIApplication.shared.isIdleTimerDisabled = isScreenOn
        }
        .onDisappear {
            // 화면 켜짐 유지 해제
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                syncDisplay(now: Date())
                maybeShowManualAlert()
                SessionStore.clearScheduledNotifications()
                if let state = sessionState, state.isPaused == false {
                    scheduleNotifications(for: state)
                }
            } else if newValue == .background || newValue == .inactive {
                if let state = sessionState {
                    if state.stepTransitionMode == .manual {
                        scheduleBackgroundRepeatNotificationsIfNeeded(state)
                    } else {
                        scheduleNotifications(for: state)
                    }
                }
            }
        }
        .onChange(of: isScreenOn) { oldValue, newValue in
            // 토글이 변경될 때 즉시 적용
            UIApplication.shared.isIdleTimerDisabled = newValue
            routine.keepScreenOn = newValue
            routine.updatedAt = Date()
            try? managedObjectContext.save()
        }
    }
    
    private func loadLastNotificationConfiguration() {
        let lastSoundEnabled = UserDefaults.standard.object(forKey: "lastUsedSoundEnabled") as? Bool ?? true
        let lastVibrationEnabled = UserDefaults.standard.object(forKey: "lastUsedVibrationEnabled") as? Bool ?? false
        let lastSoundRaw = UserDefaults.standard.string(forKey: "lastUsedSound") ?? NotificationSound.default.rawValue
        let lastVibrationRaw = UserDefaults.standard.string(forKey: "lastUsedVibration") ?? VibrationPattern.default.rawValue
        
        let lastSound = NotificationSound(rawValue: lastSoundRaw) ?? .default
        let lastVibration = VibrationPattern(rawValue: lastVibrationRaw) ?? .default
        
        if lastSoundEnabled && lastVibrationEnabled {
            configuration = NotificationConfiguration(mode: .soundAndVibration, sound: lastSound, vibration: lastVibration)
        } else if lastSoundEnabled {
            configuration = NotificationConfiguration(mode: .sound, sound: lastSound, vibration: lastVibration)
        } else if lastVibrationEnabled {
            configuration = NotificationConfiguration(mode: .vibration, sound: lastSound, vibration: lastVibration)
        }
    }
    
    private func loadOrStartSession() {
        guard !timeline.isEmpty else { return }
        if forceNewSession {
            SessionStore.clear()
            startSession()
            return
        }
        if let routineId = routine.routineId,
           let stored = SessionStore.load(),
           stored.routineId == routineId {
            sessionState = stored
            configuration = configurationFromSession(stored, fallback: configuration)
            if stored.isPaused == false {
                scheduleNotifications(for: stored)
            }
        } else {
            startSession()
        }
    }

    private func startSession() {
        guard !timeline.isEmpty else { return }
        let routineId = routine.routineId ?? UUID()
        let now = Date()
        hasSyncedOnce = false
        lastSyncedStepIndex = nil
        var coreDataSessionId: UUID? = nil
        if routine.managedObjectContext != nil {
            let session = CoreDataManager.shared.createSession(for: routine, startedAt: now)
            coreDataSessionId = session.sessionId
            NotificationCenter.default.post(name: .sessionStarted, object: routine.routineId)
        }
        let newState = SessionState(
            sessionId: coreDataSessionId ?? UUID(),
            routineId: routineId,
            startAt: now,
            isPaused: false,
            pausedAt: nil,
            accumulatedPausedSeconds: 0,
            currentStepIndex: 0,
            stepTransitionMode: initialStepTransitionMode,
            stepRunState: .running,
            notificationMode: configuration.mode,
            notificationPatternId: notificationPatternId(from: configuration),
            scheduledNotificationIds: []
        )
        sessionState = newState
        SessionStore.save(newState)
        scheduleNotifications(for: newState)
    }

    private func pauseSession() {
        guard var state = sessionState, state.isPaused == false else { return }
        state.isPaused = true
        state.pausedAt = Date()
        sessionState = state
        SessionStore.save(state)
        if let session = CoreDataManager.shared.fetchSession(by: state.sessionId) {
            let nextPauseCount = session.pauseCount + 1
            CoreDataManager.shared.updateSession(session, status: "PAUSED", pauseCount: nextPauseCount)
        }
        cancelPendingNotifications(for: state.sessionId, stepCount: timeline.count)
        syncDisplay(now: Date())
    }

    private func resumeSession() {
        guard var state = sessionState, state.isPaused else { return }
        let now = Date()
        if let pausedAt = state.pausedAt {
            state.accumulatedPausedSeconds += max(Int(now.timeIntervalSince(pausedAt)), 0)
        }
        state.isPaused = false
        state.pausedAt = nil
        if state.stepRunState == .waitingForNext {
            state.stepRunState = .running
        }
        sessionState = state
        SessionStore.save(state)
        if let session = CoreDataManager.shared.fetchSession(by: state.sessionId) {
            CoreDataManager.shared.updateSession(session, status: "RUNNING")
        }
        scheduleNotifications(for: state)
    }

    private func stopSession() {
        guard let state = sessionState else { return }
        if let session = CoreDataManager.shared.fetchSession(by: state.sessionId) {
            CoreDataManager.shared.updateSession(session, endedAt: Date(), status: "ABANDONED")
            if let sessionId = session.sessionId {
                SyncManager.shared.enqueueSession(sessionId: sessionId)
            }
        } else {
            SyncManager.shared.enqueueSession(sessionId: state.sessionId)
        }
        cancelPendingNotifications(for: state.sessionId, stepCount: timeline.count)
        sessionState = nil
        hasSyncedOnce = false
        lastSyncedStepIndex = nil
        showManualNextAlert = false
        hasShownManualAlertForStep = nil
        SessionStore.clear()
    }

    private func finishSession() {
        guard let state = sessionState else { return }
        if let session = CoreDataManager.shared.fetchSession(by: state.sessionId) {
            CoreDataManager.shared.updateSession(session, endedAt: Date(), status: "COMPLETED")
            if let sessionId = session.sessionId {
                SyncManager.shared.enqueueSession(sessionId: sessionId)
            }
        } else {
            SyncManager.shared.enqueueSession(sessionId: state.sessionId)
        }
        hasSyncedOnce = false
        lastSyncedStepIndex = nil
        showManualNextAlert = false
        hasShownManualAlertForStep = nil
        cancelPendingNotifications(for: state.sessionId, stepCount: timeline.count)
        SessionStore.clear()
        showFinishAlert = true
    }

    private func handlePrimaryAction() {
        if sessionState == nil {
            startSession()
            syncDisplay(now: Date())
            return
        }
        switch sessionState?.isPaused {
        case .some(false):
            pauseSession()
        case .some(true):
            resumeSession()
        default:
            break
        }
    }

    private var primaryActionLabel: String {
        switch sessionState?.isPaused {
        case .some(false):
            return String(localized: "common.pause", locale: locale)
        case .some(true):
            return String(localized: "common.resume", locale: locale)
        default:
            return String(localized: "common.start", locale: locale)
        }
    }

    private var primaryActionIconName: String {
        switch sessionState?.isPaused {
        case .some(false):
            return "pause.fill"
        default:
            return "play.fill"
        }
    }

    private func skipToNextStep() {
        guard var state = sessionState else { return }
        guard !timeline.isEmpty else { return }
        if state.currentStepIndex >= timeline.count - 1 {
            finishSession()
            return
        }
        let nextIndex = min(state.currentStepIndex + 1, timeline.count - 1)
        let now = Date()
        state.currentStepIndex = nextIndex
        state.startAt = now.addingTimeInterval(TimeInterval(-timeline[nextIndex].startOffset))
        state.isPaused = false
        state.pausedAt = nil
        state.accumulatedPausedSeconds = 0
        state.stepRunState = .running
        sessionState = state
        SessionStore.save(state)
        scheduleNotifications(for: state)
        syncDisplay(now: Date())
    }
    
    private func playNotification() {
        switch configuration.mode {
        case .sound:
            AudioManager.shared.playSound(configuration.sound)
        case .vibration:
            HapticManager.shared.playVibration(configuration.vibration)
        case .soundAndVibration:
            AudioManager.shared.playSound(configuration.sound)
            HapticManager.shared.playVibration(configuration.vibration)
        }
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func syncDisplay(now: Date) {
        guard var state = sessionState else { return }
        guard !timeline.isEmpty else { return }
        let stepIndex = min(max(state.currentStepIndex, 0), timeline.count - 1)
        let elapsed = state.activeElapsedSeconds(now: now)
        let endOffset = timeline[stepIndex].endOffset
        if elapsed >= endOffset {
            if state.stepTransitionMode == .manual {
                if state.stepRunState != .waitingForNext {
                    let over = elapsed - endOffset
                    if over > 0 {
                        state.accumulatedPausedSeconds += over
                    }
                }
                state.isPaused = true
                state.pausedAt = now
                state.stepRunState = .waitingForNext
                sessionState = state
                SessionStore.save(state)
                cancelPendingNotifications(for: state.sessionId, stepCount: timeline.count)
                currentStepIndex = stepIndex
                remainingSeconds = 0
                maybeShowManualAlert()
                return
            } else {
                var updatedState = state
                // In auto mode, derive the current index from elapsed without mutating startAt.
                var targetIndex = stepIndex
                for item in timeline {
                    if elapsed < item.endOffset {
                        targetIndex = item.index
                        break
                    }
                    targetIndex = item.index
                }
                if elapsed >= (timeline.last?.endOffset ?? 0) {
                    updatedState.stepRunState = .completed
                    sessionState = updatedState
                    SessionStore.save(updatedState)
                    finishSession()
                    return
                }

                let didAdvance = targetIndex != updatedState.currentStepIndex
                updatedState.currentStepIndex = targetIndex
                updatedState.isPaused = false
                updatedState.pausedAt = nil
                updatedState.stepRunState = .running

                if didAdvance && scenePhase == .active {
                    playNotification()
                    triggerAutoAdvanceAlert()
                }
                sessionState = updatedState
                SessionStore.save(updatedState)
                scheduleNotifications(for: updatedState)
                currentStepIndex = updatedState.currentStepIndex
                let newEnd = timeline[currentStepIndex].endOffset
                remainingSeconds = max(newEnd - elapsed, 0)
                return
            }
        }
        currentStepIndex = stepIndex
        remainingSeconds = max(endOffset - elapsed, 0)
        if !hasSyncedOnce {
            hasSyncedOnce = true
            lastSyncedStepIndex = currentStepIndex
            return
        }
        if lastSyncedStepIndex != currentStepIndex && state.isPaused == false {
            lastSyncedStepIndex = currentStepIndex
        }
    }

    private func scheduleNotifications(for state: SessionState) {
        guard !timeline.isEmpty else { return }
        let elapsed = state.activeElapsedSeconds(now: Date())
        var requests: [UNNotificationRequest] = []
        var identifiers: [String] = []
        let stepIndex = min(max(state.currentStepIndex, 0), timeline.count - 1)
        if state.stepTransitionMode == .auto {
            for item in timeline where item.endOffset > elapsed {
                let remaining = item.endOffset - elapsed
                if remaining <= 0 { continue }
                let content = UNMutableNotificationContent()
                let identifier: String
                if item.index == timeline.count - 1 {
                    content.title = String(localized: "notification.title.routineComplete", locale: locale)
                    let routineName = routine.name ?? String(localized: "app.routine.defaultName", locale: locale)
                    content.body = String(format: String(localized: "notification.body.routineComplete", locale: locale), routineName)
                    identifier = completionNotificationIdentifier(sessionId: state.sessionId)
                } else {
                    let nextName = timeline[item.index + 1].name
                    content.title = String(localized: "notification.title.stepComplete", locale: locale)
                    content.body = String(format: String(localized: "notification.body.stepComplete", locale: locale), item.name, nextName)
                    identifier = notificationIdentifier(sessionId: state.sessionId, stepIndex: item.index)
                }
                content.sound = notificationSound(for: configuration)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remaining), repeats: false)
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
                identifiers.append(identifier)
            }
        } else {
            let item = timeline[stepIndex]
            let remaining = item.endOffset - elapsed
            if remaining > 0 {
                let content = UNMutableNotificationContent()
                let identifier: String
                if item.index == timeline.count - 1 {
                    content.title = String(localized: "notification.title.routineComplete", locale: locale)
                    let routineName = routine.name ?? String(localized: "app.routine.defaultName", locale: locale)
                    content.body = String(format: String(localized: "notification.body.routineComplete", locale: locale), routineName)
                    identifier = completionNotificationIdentifier(sessionId: state.sessionId)
                } else {
                    let nextName = timeline[item.index + 1].name
                    content.title = String(localized: "notification.title.stepComplete", locale: locale)
                    content.body = String(format: String(localized: "notification.body.stepComplete", locale: locale), item.name, nextName)
                    identifier = notificationIdentifier(sessionId: state.sessionId, stepIndex: item.index)
                }
                content.sound = notificationSound(for: configuration)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remaining), repeats: false)
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
                identifiers.append(identifier)
            }
        }

        cancelPendingNotifications(for: state.sessionId, stepCount: timeline.count)
        let center = UNUserNotificationCenter.current()
        for request in requests {
            center.add(request, withCompletionHandler: nil)
        }
        if var updated = sessionState {
            updated.scheduledNotificationIds = identifiers
            sessionState = updated
            SessionStore.save(updated)
        }
    }

    private func scheduleBackgroundRepeatNotificationsIfNeeded(_ state: SessionState) {
        guard state.stepTransitionMode == .manual else { return }
        guard state.isPaused == false else { return }
        guard !timeline.isEmpty else { return }
        let stepIndex = min(max(state.currentStepIndex, 0), timeline.count - 1)
        let elapsed = state.activeElapsedSeconds(now: Date())
        let endOffset = timeline[stepIndex].endOffset
        let remaining = endOffset - elapsed
        guard remaining > 0 else { return }

        SessionStore.clearScheduledNotifications()

        var requests: [UNNotificationRequest] = []
        var identifiers: [String] = []
        for offsetIndex in 0..<backgroundRepeatCount {
            let fireAfter = TimeInterval(remaining) + (backgroundRepeatInterval * Double(offsetIndex))
            let content = UNMutableNotificationContent()
            if stepIndex == timeline.count - 1 {
                content.title = String(localized: "notification.title.routineComplete", locale: locale)
                let routineName = routine.name ?? String(localized: "app.routine.defaultName", locale: locale)
                content.body = String(format: String(localized: "notification.body.routineComplete", locale: locale), routineName)
            } else {
                let nextName = timeline[stepIndex + 1].name
                content.title = String(localized: "notification.title.stepComplete", locale: locale)
                content.body = String(format: String(localized: "notification.body.stepComplete", locale: locale), timeline[stepIndex].name, nextName)
            }
            content.threadIdentifier = "seqtimer.repeat.\(state.sessionId.uuidString)"
            content.sound = notificationSound(for: configuration)
            let identifier = backgroundRepeatIdentifier(sessionId: state.sessionId, stepIndex: stepIndex, repeatIndex: offsetIndex)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireAfter, repeats: false)
            requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            identifiers.append(identifier)
        }

        let center = UNUserNotificationCenter.current()
        for request in requests {
            center.add(request, withCompletionHandler: nil)
        }
        if var updated = sessionState {
            updated.scheduledNotificationIds = identifiers
            sessionState = updated
            SessionStore.save(updated)
        }
    }

    private func backgroundRepeatIdentifier(sessionId: UUID, stepIndex: Int, repeatIndex: Int) -> String {
        "seqtimer.\(sessionId.uuidString).step.\(stepIndex).repeat.\(repeatIndex)"
    }

    private func cancelPendingNotifications(for sessionId: UUID, stepCount: Int) {
        guard stepCount > 0 else { return }
        let identifiers = (0..<stepCount).map { notificationIdentifier(sessionId: sessionId, stepIndex: $0) }
            + [completionNotificationIdentifier(sessionId: sessionId)]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func notificationSound(for configuration: NotificationConfiguration) -> UNNotificationSound? {
        switch configuration.mode {
        case .sound, .soundAndVibration:
            if let resource = configuration.sound.audioResourceName {
                return UNNotificationSound(named: UNNotificationSoundName(rawValue: resource))
            }
            return .default
        case .vibration:
            return nil
        }
    }

    private func notificationPatternId(from configuration: NotificationConfiguration) -> String {
        switch configuration.mode {
        case .sound, .soundAndVibration:
            switch configuration.sound {
            case .default:
                return "basic"
            case .short:
                return "short"
            case .soft:
                return "soft"
            }
        case .vibration:
            switch configuration.vibration {
            case .default:
                return "basic"
            case .short:
                return "short"
            case .double:
                return "double"
            case .heavy:
                return "heavy"
            }
        }
    }

    private func applyConfiguration(_ configuration: NotificationConfiguration, to state: inout SessionState) {
        state.notificationMode = configuration.mode
        state.notificationPatternId = notificationPatternId(from: configuration)
    }

    private func configurationFromSession(_ state: SessionState, fallback: NotificationConfiguration) -> NotificationConfiguration {
        switch state.notificationMode {
        case .vibration:
            let vibration: VibrationPattern
            switch state.notificationPatternId {
            case "short":
                vibration = .short
            case "double":
                vibration = .double
            case "heavy":
                vibration = .heavy
            default:
                vibration = .default
            }
            return NotificationConfiguration(mode: .vibration, sound: fallback.sound, vibration: vibration)
        case .sound, .soundAndVibration:
            let sound: NotificationSound
            switch state.notificationPatternId {
            case "short":
                sound = .short
            case "soft":
                sound = .soft
            default:
                sound = .default
            }
            return NotificationConfiguration(mode: state.notificationMode, sound: sound, vibration: fallback.vibration)
        }
    }

    private func maybeShowManualAlert() {
        guard scenePhase == .active else { return }
        guard let state = sessionState else { return }
        guard state.stepTransitionMode == .manual else { return }
        guard state.stepRunState == .waitingForNext else { return }
        if hasShownManualAlertForStep == state.currentStepIndex { return }
        hasShownManualAlertForStep = state.currentStepIndex
        if didOpenFromNotification {
            didOpenFromNotification = false
        } else {
            playNotificationRepeating(count: 5, interval: 2.2)
        }
        showManualNextAlert = true
    }

    private var manualAlertShowsLaterButton: Bool {
        let nextIndex = currentStepIndex + 1
        return nextIndex < timeline.count
    }

    private var manualAlertTitle: String {
        String(localized: "timer.running.manualAlert.title", locale: locale)
    }

    private var manualAlertMessage: String {
        if isLastStep {
            return String(localized: "timer.running.manualAlert.message.last", locale: locale)
        }
        return String(localized: "timer.running.manualAlert.message.next", locale: locale)
    }

    private var manualAlertPrimaryLabel: String {
        if isLastStep {
            return String(localized: "common.confirm", locale: locale)
        }
        return String(localized: "common.startNow", locale: locale)
    }

    private var isLastStep: Bool {
        let nextIndex = currentStepIndex + 1
        return nextIndex >= timeline.count
    }

    private func startNextStepFromManualAlert() {
        guard var state = sessionState else { return }
        guard state.stepTransitionMode == .manual else { return }
        guard state.stepRunState == .waitingForNext else { return }
        guard !timeline.isEmpty else { return }
        let nextIndex = state.currentStepIndex + 1
        if nextIndex >= timeline.count {
            cancelManualAlertNotifications()
            finishSession()
            return
        }
        let now = Date()
        state.currentStepIndex = nextIndex
        state.startAt = now.addingTimeInterval(TimeInterval(-timeline[nextIndex].startOffset))
        state.isPaused = false
        state.pausedAt = nil
        state.accumulatedPausedSeconds = 0
        state.stepRunState = .running
        sessionState = state
        SessionStore.save(state)
        scheduleNotifications(for: state)
        cancelManualAlertNotifications()
        showManualNextAlert = false
        syncDisplay(now: Date())
    }

    private func triggerAutoAdvanceAlert() {
        showAutoAdvanceAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showAutoAdvanceAlert = false
        }
    }

    private func handleManualAlertLater() {
        guard var state = sessionState else { return }
        guard state.stepTransitionMode == .manual else { return }
        guard !timeline.isEmpty else { return }
        let nextIndex = state.currentStepIndex + 1
        if nextIndex >= timeline.count {
            finishSession()
            return
        }
        let now = Date()
        state.currentStepIndex = nextIndex
        state.startAt = now.addingTimeInterval(TimeInterval(-timeline[nextIndex].startOffset))
        state.accumulatedPausedSeconds = 0
        state.isPaused = true
        state.pausedAt = now
        state.stepRunState = .waitingForNext
        sessionState = state
        SessionStore.save(state)
        cancelPendingNotifications(for: state.sessionId, stepCount: timeline.count)
        cancelManualAlertNotifications()
        showManualNextAlert = false
        syncDisplay(now: Date())
    }

    private func playNotificationRepeating(count: Int, interval: TimeInterval) {
        guard count > 0 else { return }
        cancelManualAlertNotifications()
        for index in 0..<count {
            let workItem = DispatchWorkItem {
                playNotification()
            }
            manualAlertNotificationTimers.append(workItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + (interval * Double(index)), execute: workItem)
        }
    }

    private func cancelManualAlertNotifications() {
        manualAlertNotificationTimers.forEach { $0.cancel() }
        manualAlertNotificationTimers = []
    }

    private func formatTime(_ seconds: Int) -> String {
        let total = max(seconds, 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    var configDisplayText: String {
        switch configuration.mode {
        case .sound:
            return String(localized: "notification.mode.sound", locale: locale)
        case .vibration:
            return String(localized: "notification.mode.vibration", locale: locale)
        case .soundAndVibration:
            return String(localized: "notification.mode.soundAndVibration.compact", locale: locale)
        }
    }

    var transitionDisplayText: String {
        let mode = sessionState?.stepTransitionMode ?? initialStepTransitionMode
        switch mode {
        case .auto:
            return String(localized: "transition.mode.auto", locale: locale)
        case .manual:
            return String(localized: "transition.mode.manual", locale: locale)
        }
    }
}

extension Notification.Name {
    static let sessionStarted = Notification.Name("seqtimer.sessionStarted")
}

#Preview {
    // Use a simple stub for preview
    let stub = Routine()
    TimerRunningView(routine: stub, initialConfiguration: nil, initialStepTransitionMode: .manual, forceNewSession: true)
}

// MARK: - Local Managers (Consolidated for compilation visibility)

class AudioManager: NSObject {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Failed to set up audio session
        }
    }
    
    func playSound(_ sound: NotificationSound) {
        let systemSoundID: SystemSoundID
        switch sound {
        case .default: systemSoundID = 1007  // Standard notification
        case .short: systemSoundID = 1003    // Short bell sound
        case .soft: systemSoundID = 1001     // Soft bell tone
        }
        
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func stop() {
        audioPlayer?.stop()
    }
}

class HapticManager {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    
    init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    func playVibration(_ pattern: VibrationPattern) {
        // Fallback for simple haptics if engine fails or for simple patterns
        switch pattern {
        case .default:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .short:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .double:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                generator.impactOccurred()
            }
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
}
