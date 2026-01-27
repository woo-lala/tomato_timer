
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
    
    let routine: Routine
    let initialConfiguration: NotificationConfiguration?
    @State private var configuration: NotificationConfiguration = .default
    @State private var showAlarmSettings: Bool = false
    
    // Timer State
    @State private var currentStepIndex: Int = 0
    @State private var remainingSeconds: Int = 0
    @State private var totalSeconds: Int = 0
    @State private var isScreenOn: Bool
    @State private var isPaused: Bool = false
    @State private var isRunning: Bool = true
    @State private var showFinishAlert: Bool = false
    @State private var showStepAlert: Bool = false
    @State private var isAwaitingStepConfirmation: Bool = false
    @State private var notificationRepeatTimer: Timer?
    @State private var backgroundTimestamp: Date?
    @State private var backgroundRemainingSeconds: Int = 0
    @State private var backgroundStepIndex: Int = 0
    @State private var lastTickDate: Date?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(routine: Routine, initialConfiguration: NotificationConfiguration?) {
        self.routine = routine
        self.initialConfiguration = initialConfiguration
        _isScreenOn = State(initialValue: routine.keepScreenOn)
    }
    
    var sortedSteps: [RoutineStep] {
        let steps = routine.steps as? Set<RoutineStep> ?? []
        return steps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
    }
    
    var currentStep: RoutineStep? {
        guard currentStepIndex < sortedSteps.count else { return nil }
        return sortedSteps[currentStepIndex]
    }
    
    var nextStep: RoutineStep? {
        guard currentStepIndex + 1 < sortedSteps.count else { return nil }
        return sortedSteps[currentStepIndex + 1]
    }
    
    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var currentStepName: String {
        currentStep?.type ?? "작업"
    }
    
    var nextStepInfo: String {
        if let next = nextStep {
            if next.seconds > 0 {
                return "다음: \(next.type ?? "작업") (\(next.minutes)분 \(next.seconds)초)"
            } else {
                return "다음: \(next.type ?? "작업") (\(next.minutes)분)"
            }
        }
        return "마지막 단계"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Central Card
                    VStack(spacing: 20) {
                        // Step Badge
                        Text("\(currentStepIndex + 1)/\(sortedSteps.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColor.primary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(AppColor.primary.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.top, 20)
                        
                        // Current Step Name
                        Text(currentStepName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        // Timer Display
                        Text(timeString)
                            .font(.system(size: 80, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColor.primary)
                            .padding(.vertical, 10)
                            .minimumScaleFactor(0.5)
                        
                        // Next Step Info
                        Text(nextStepInfo)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                    }
                    .padding(AppSpacing.mediumPlus)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .offset(y: -32)
                    
                    // Options below card
                    VStack(spacing: 20) {
                        Toggle("화면 켜짐 유지", isOn: $isScreenOn)
                            .toggleStyle(SwitchToggleStyle(tint: AppColor.primary))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        Button(action: {
                            showAlarmSettings = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.gray)
                                Text("알림 모드: \(configDisplayText)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
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
                            Text("종료")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        // Pause/Play Button
                        VStack(spacing: 8) {
                            Button(action: {
                                isPaused.toggle()
                            }) {
                                Circle()
                                    .fill(AppColor.primary)
                                    .frame(width: 72, height: 72)
                                    .shadow(color: AppColor.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                            .offset(x: isPaused ? 2 : 0)
                                    )
                            }
                            Text(isPaused ? "재개" : "일시정지")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        // Skip Button
                        VStack(spacing: 8) {
                            Button(action: {
                                skipToNextStep()
                            }) {
                                Circle()
                                    .fill(Color(UIColor.systemGray6))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.gray)
                                    )
                            }
                            Text("건너뛰기")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(routine.name ?? "루틴")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .alert("루틴 종료", isPresented: $showFinishAlert) {
                Button("확인", action: {
                    dismiss()
                })
            } message: {
                Text("모든 단계를 완료했습니다!")
            }
            .alert("단계 완료", isPresented: $showStepAlert) {
                Button(currentStepIndex >= sortedSteps.count - 1 ? "확인" : "다음 단계", action: {
                    handleStepAlertConfirm()
                })
            } message: {
                if currentStepIndex >= sortedSteps.count - 1 {
                    Text("모든 단계를 완료했습니다!")
                } else if let next = nextStep {
                    Text("다음: \(next.type ?? "작업")로 넘어갈까요?")
                } else {
                    Text("다음 단계로 넘어갈까요?")
                }
            }
            .sheet(isPresented: $showAlarmSettings) {
                NotificationModeSheet(routine: routine, onStart: { selectedRoutine, config in
                    configuration = config
                    showAlarmSettings = false
                })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(timer) { _ in
            let now = Date()
            guard isRunning && !isPaused else {
                lastTickDate = now
                return
            }

            let elapsed = max(1, Int(now.timeIntervalSince(lastTickDate ?? now)))
            lastTickDate = now
            if elapsed <= 0 { return }
            applyElapsedTime(elapsed, startingFrom: currentStepIndex, startingRemaining: remainingSeconds)
        }
        .onAppear {
            if let initial = initialConfiguration {
                configuration = initial
            } else {
                loadLastNotificationConfiguration()
            }
            initializeTimer()
            lastTickDate = Date()
            requestNotificationAuthorization()
            // 화면 켜짐 유지 설정
            UIApplication.shared.isIdleTimerDisabled = isScreenOn
        }
        .onDisappear {
            // 화면 켜짐 유지 해제
            UIApplication.shared.isIdleTimerDisabled = false
            stopNotificationLoop()
            clearStepCompletionNotifications()
        }
        .onChange(of: scenePhase) { _, newValue in
            handleScenePhaseChange(newValue)
        }
        .onChange(of: isPaused) { _, _ in
            lastTickDate = Date()
        }
        .onChange(of: isScreenOn) { oldValue, newValue in
            // 토글이 변경될 때 즉시 적용
            UIApplication.shared.isIdleTimerDisabled = newValue
            routine.keepScreenOn = newValue
            routine.updatedAt = Date()
            try? managedObjectContext.save()
        }
    }
    
    private func initializeTimer() {
        guard !sortedSteps.isEmpty else { return }
        currentStepIndex = 0
        if let step = currentStep {
            remainingSeconds = Int(step.minutes) * 60 + Int(step.seconds)
            totalSeconds = remainingSeconds
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
    
    private func skipToNextStep() {
        // 마지막 단계에서 건너뛰기를 누른 경우
        if currentStepIndex >= sortedSteps.count - 1 {
            playNotification()
            showFinishAlert = true
            return
        }
        
        playNotification()
        moveToNextStep()
    }
    
    private func handleStepCompletion() {
        isAwaitingStepConfirmation = true
        isPaused = true
        showStepAlert = true
        startNotificationLoop()
    }
    
    private func handleStepAlertConfirm() {
        stopNotificationLoop()
        showStepAlert = false
        isAwaitingStepConfirmation = false
        
        if currentStepIndex >= sortedSteps.count - 1 {
            isRunning = false
            dismiss()
            return
        }
        
        moveToNextStep()
        isPaused = false
    }
    
    private func moveToNextStep() {
        if currentStepIndex < sortedSteps.count - 1 {
            currentStepIndex += 1
            if let step = currentStep {
                remainingSeconds = Int(step.minutes) * 60 + Int(step.seconds)
                totalSeconds = remainingSeconds
            }
        } else {
            // 마지막 단계에서 시간이 끝났을 때 자동으로 종료
            isRunning = false
            playNotification()
            showFinishAlert = true
        }
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
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            guard isRunning && !isPaused && !isAwaitingStepConfirmation else { return }
            backgroundTimestamp = Date()
            backgroundRemainingSeconds = remainingSeconds
            backgroundStepIndex = currentStepIndex
            scheduleStepCompletionNotification(after: remainingSeconds)
        case .active:
            clearStepCompletionNotifications()
            guard let backgroundTimestamp else { return }
            let elapsed = Int(Date().timeIntervalSince(backgroundTimestamp))
            self.backgroundTimestamp = nil
            if elapsed <= 0 { return }
            if elapsed >= backgroundRemainingSeconds {
                currentStepIndex = backgroundStepIndex
                remainingSeconds = 0
                totalSeconds = backgroundRemainingSeconds
                isPaused = true
                isAwaitingStepConfirmation = true
                showStepAlert = true
            } else {
                applyElapsedTime(elapsed, startingFrom: backgroundStepIndex, startingRemaining: backgroundRemainingSeconds)
            }
            lastTickDate = Date()
        @unknown default:
            break
        }
    }
    
    private func applyElapsedTime(_ elapsed: Int, startingFrom stepIndex: Int, startingRemaining: Int) {
        var remainingElapsed = elapsed
        var index = stepIndex
        var remaining = startingRemaining
        
        while remainingElapsed >= remaining && index < sortedSteps.count {
            remainingElapsed -= remaining
            index += 1
            if index >= sortedSteps.count {
                isRunning = false
                showFinishAlert = true
                return
            }
            let next = sortedSteps[index]
            remaining = Int(next.minutes) * 60 + Int(next.seconds)
        }
        
        currentStepIndex = index
        remainingSeconds = max(remaining - remainingElapsed, 0)
        totalSeconds = remaining
    }
    
    private func startNotificationLoop() {
        playNotification()
        notificationRepeatTimer?.invalidate()
        notificationRepeatTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            playNotification()
        }
    }
    
    private func stopNotificationLoop() {
        notificationRepeatTimer?.invalidate()
        notificationRepeatTimer = nil
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleStepCompletionNotification(after seconds: Int) {
        guard seconds > 0 else { return }
        clearStepCompletionNotifications()
        let content = UNMutableNotificationContent()
        content.title = "단계 완료"
        content.body = "\(currentStepName) 완료. 다음 단계로 넘어가세요."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "routineStepComplete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func clearStepCompletionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["routineStepComplete"])
    }
    
    var configDisplayText: String {
        switch configuration.mode {
        case .sound:
            return "소리"
        case .vibration:
            return "진동"
        case .soundAndVibration:
            return "소리+진동"
        }
    }
}

#Preview {
    // Use a simple stub for preview
    let stub = Routine()
    TimerRunningView(routine: stub, initialConfiguration: nil)
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
