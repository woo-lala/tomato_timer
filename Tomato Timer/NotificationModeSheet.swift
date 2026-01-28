
import SwiftUI

struct NotificationModeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Routine data
    let routine: Routine
    
    // Config State
    @State private var useSound: Bool = true
    @State private var useVibration: Bool = false
    
    @State private var selectedSound: NotificationSound = .default
    @State private var selectedVibration: VibrationPattern = .default
    
    // Persistence
    @AppStorage("lastUsedSoundEnabled") private var lastSoundEnabled: Bool = true
    @AppStorage("lastUsedVibrationEnabled") private var lastVibrationEnabled: Bool = false
    @AppStorage("lastUsedSound") private var lastSoundRaw: String = NotificationSound.default.rawValue
    @AppStorage("lastUsedVibration") private var lastVibrationRaw: String = VibrationPattern.default.rawValue
    
    @State private var stepTransitionMode: StepTransitionMode = .manual

    var onStart: (Routine, NotificationConfiguration, StepTransitionMode) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("알림 방식")
                    .font(AppFont.title())
                    .foregroundColor(AppColor.textPrimary)
                
                // Quick Presets
                HStack(spacing: 12) {
                    Button(action: loadBasicSettings) {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                            Text("기본값")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColor.primary.opacity(0.1))
                        .cornerRadius(AppRadius.button)
                    }
                    
                    Button(action: loadLastUsedSettings) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                            Text("이전 설정")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColor.primary.opacity(0.1))
                        .cornerRadius(AppRadius.button)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.mediumPlus)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Step Transition Mode
                    VStack(spacing: 0) {
                        HStack {
                            Text("전환 방식")
                                .foregroundColor(AppColor.textPrimary)
                            Spacer()
                            Picker("전환 방식", selection: $stepTransitionMode) {
                                Text("자동").tag(StepTransitionMode.auto)
                                Text("수동").tag(StepTransitionMode.manual)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                    .background(Color.white)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)

                    // Sound Section
                    VStack(spacing: 0) {
                        ToggleRow(title: "소리", isOn: $useSound)
                        
                        if useSound {
                            Divider().padding(.leading, AppSpacing.medium)
                            
                            Button(action: {
                                // Show sound picker? No, inline expansion or sheet
                                // Let's use Menu or NavigationLink-ish behavior or just expand
                                // Keeping it simple with existing sheet approach or inline menu
                            }) {
                                HStack {
                                    Text("알림음")
                                        .foregroundColor(AppColor.textPrimary)
                                    Spacer()
                                    Menu {
                                        ForEach(NotificationSound.allCases, id: \.self) { sound in
                                            Button(action: {
                                                selectedSound = sound
                                                AudioManager.shared.playSound(sound)
                                            }) {
                                                if selectedSound == sound {
                                                    Label(sound.rawValue, systemImage: "checkmark")
                                                } else {
                                                    Text(sound.rawValue)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedSound.rawValue)
                                                .foregroundColor(AppColor.textSecondary)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColor.textSecondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, AppSpacing.medium)
                                .padding(.vertical, AppSpacing.smallPlus)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    
                    // Vibration Section
                    VStack(spacing: 0) {
                        ToggleRow(title: "진동", isOn: $useVibration)
                        
                        if useVibration {
                            Divider().padding(.leading, AppSpacing.medium)
                            
                            HStack {
                                Text("진동 패턴")
                                    .foregroundColor(AppColor.textPrimary)
                                Spacer()
                                Menu {
                                    ForEach(VibrationPattern.allCases, id: \.self) { pattern in
                                        Button(action: {
                                            selectedVibration = pattern
                                            HapticManager.shared.playVibration(pattern)
                                        }) {
                                            if selectedVibration == pattern {
                                                Label(pattern.rawValue, systemImage: "checkmark")
                                            } else {
                                                Text(pattern.rawValue)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedVibration.rawValue)
                                            .foregroundColor(AppColor.textSecondary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColor.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.medium)
                            .padding(.vertical, AppSpacing.smallPlus)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, 20)
            }
            
            Spacer()
            
            // Start Button
            Button(action: startRoutine) {
                Text("시작")
                    .font(AppFont.button())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canStart ? AppColor.primary : Color.gray)
                    .cornerRadius(AppRadius.button)
            }
            .disabled(!canStart)
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.bottom, AppSpacing.large)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            // Load last used by default? Users request: "Basic or Previous can be selected"
            // Let's load Last Used by default for convenience
            loadLastUsedSettings()
        }
    }
    
    var canStart: Bool {
        return useSound || useVibration
    }
    
    private func loadBasicSettings() {
        useSound = true
        useVibration = false
        selectedSound = .default
        selectedVibration = .default
    }
    
    private func loadLastUsedSettings() {
        useSound = lastSoundEnabled
        useVibration = lastVibrationEnabled
        selectedSound = NotificationSound(rawValue: lastSoundRaw) ?? .default
        selectedVibration = VibrationPattern(rawValue: lastVibrationRaw) ?? .default
    }
    
    private func startRoutine() {
        // Save current settings
        lastSoundEnabled = useSound
        lastVibrationEnabled = useVibration
        lastSoundRaw = selectedSound.rawValue
        lastVibrationRaw = selectedVibration.rawValue
        
        // Create Config
        let mode: NotificationMode
        if useSound && useVibration {
            mode = .soundAndVibration
        } else if useSound {
            mode = .sound
        } else {
            mode = .vibration
        }
        
        let config = NotificationConfiguration(mode: mode, sound: selectedSound, vibration: selectedVibration)
        onStart(routine, config, stepTransitionMode)
        dismiss()
    }
}
