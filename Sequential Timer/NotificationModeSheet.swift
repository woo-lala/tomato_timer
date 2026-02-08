
import SwiftUI
import Foundation

struct NotificationModeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themePalette) private var theme
    @Environment(\.locale) private var locale
    
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
    @AppStorage("defaultNotificationSound") private var defaultSoundRaw: String = NotificationSound.default.rawValue
    @AppStorage("defaultNotificationVibration") private var defaultVibrationRaw: String = VibrationPattern.default.rawValue
    
    @State private var stepTransitionMode: StepTransitionMode = .manual

    var onStart: (Routine, NotificationConfiguration, StepTransitionMode) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("sheet.notificationMode.title")
                    .font(AppFont.title())
                    .foregroundColor(theme.textPrimary)
                
                // Quick Presets
                HStack(spacing: 12) {
                    Button(action: loadBasicSettings) {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                            Text("sheet.notificationMode.preset.basic")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.accent.opacity(0.1))
                        .cornerRadius(AppRadius.button)
                    }
                    
                    Button(action: loadLastUsedSettings) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                            Text("sheet.notificationMode.preset.previous")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.accent.opacity(0.1))
                        .cornerRadius(AppRadius.button)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.mediumPlus)

            VStack(spacing: 16) {
                // Step Transition Mode
                VStack(alignment: .leading, spacing: 10) {
                    Text("sheet.notificationMode.step.title")
                        .font(AppFont.callout())
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, AppSpacing.mediumPlus)

                    HStack(spacing: 12) {
                        transitionModeCard(
                            title: String(localized: "sheet.notificationMode.step.auto.title", locale: locale),
                            subtitle: String(localized: "sheet.notificationMode.step.auto.subtitle", locale: locale),
                            systemImage: "arrow.triangle.2.circlepath",
                            mode: .auto
                        )
                        transitionModeCard(
                            title: String(localized: "sheet.notificationMode.step.manual.title", locale: locale),
                            subtitle: String(localized: "sheet.notificationMode.step.manual.subtitle", locale: locale),
                            systemImage: "play.circle",
                            mode: .manual
                        )
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }

                // Notification Mode
                VStack(alignment: .leading, spacing: 10) {
                    Text("sheet.notificationMode.alert.title")
                        .font(AppFont.callout())
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, AppSpacing.mediumPlus)

                    HStack(spacing: 10) {
                        notificationModeButton(title: String(localized: "notification.mode.sound", locale: locale), systemImage: "speaker.wave.2", mode: .sound)
                        notificationModeButton(title: String(localized: "notification.mode.vibration", locale: locale), systemImage: "iphone.radiowaves.left.and.right", mode: .vibration)
                        notificationModeButton(title: String(localized: "notification.mode.soundAndVibration", locale: locale), systemImage: "bell.badge", mode: .soundAndVibration)
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
            }
            .padding(.bottom, AppSpacing.large)

            // Start Button
            Button(action: startRoutine) {
                Text("sheet.notificationMode.start")
                    .font(AppFont.button())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canStart ? theme.accent : Color.gray)
                    .cornerRadius(AppRadius.button)
            }
            .disabled(!canStart)
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.bottom, AppSpacing.large)
        }
        .background(theme.background)
        .onAppear {
            // Load last used by default? Users request: "Basic or Previous can be selected"
            // Let's load Last Used by default for convenience
            loadLastUsedSettings()
        }
    }
    
    var canStart: Bool {
        return useSound || useVibration
    }

    private var selectedNotificationMode: NotificationMode {
        if useSound && useVibration { return .soundAndVibration }
        if useSound { return .sound }
        return .vibration
    }
    
    private func loadBasicSettings() {
        useSound = true
        useVibration = false
        selectedSound = NotificationSound(rawValue: defaultSoundRaw) ?? .default
        selectedVibration = VibrationPattern(rawValue: defaultVibrationRaw) ?? .default
    }
    
    private func loadLastUsedSettings() {
        useSound = lastSoundEnabled
        useVibration = lastVibrationEnabled
        selectedSound = NotificationSound(rawValue: defaultSoundRaw) ?? .default
        selectedVibration = VibrationPattern(rawValue: defaultVibrationRaw) ?? .default
    }
    
    private func startRoutine() {
        // Save current settings
        lastSoundEnabled = useSound
        lastVibrationEnabled = useVibration
        lastSoundRaw = selectedSound.rawValue
        lastVibrationRaw = selectedVibration.rawValue
        
        // Create Config
        let config = NotificationConfiguration(mode: selectedNotificationMode, sound: selectedSound, vibration: selectedVibration)
        onStart(routine, config, stepTransitionMode)
        dismiss()
    }

    private func transitionModeCard(title: String, subtitle: String, systemImage: String, mode: StepTransitionMode) -> some View {
        let isSelected = stepTransitionMode == mode
        return Button(action: {
            stepTransitionMode = mode
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
                    Text(title)
                    .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .padding(10)
            .background(isSelected ? theme.accent.opacity(0.1) : theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .stroke(isSelected ? theme.accent : theme.border, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(AppRadius.button)
        }
        .buttonStyle(.plain)
    }

    private func notificationModeButton(title: String, systemImage: String, mode: NotificationMode) -> some View {
        let isSelected = selectedNotificationMode == mode
        let displayTitle: String
        if localeUsesEnglishLineBreak && mode == .soundAndVibration {
            displayTitle = String(localized: "notification.mode.soundAndVibration.multiline", locale: locale)
        } else {
            displayTitle = title
        }
        return Button(action: {
            switch mode {
            case .sound:
                useSound = true
                useVibration = false
            case .vibration:
                useSound = false
                useVibration = true
            case .soundAndVibration:
                useSound = true
                useVibration = true
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
                Text(displayTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(isSelected ? theme.accent.opacity(0.1) : theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .stroke(isSelected ? theme.accent : theme.border, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(AppRadius.button)
        }
        .buttonStyle(.plain)
    }

    private var localeUsesEnglishLineBreak: Bool {
        guard let code = Locale.current.language.languageCode?.identifier else { return false }
        return code == "en"
    }
}
