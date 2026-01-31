
import SwiftUI

struct SettingsView: View {
    // Settings State
    @AppStorage("keepScreenOn") private var keepScreenOn = false
    @AppStorage("defaultNotificationSound") private var defaultSoundRaw: String = NotificationSound.default.rawValue
    @AppStorage("defaultNotificationVibration") private var defaultVibrationRaw: String = VibrationPattern.default.rawValue
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.themePalette) private var theme
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Content starts with first section
                // Section 1: 타이머
                VStack(spacing: 0) {
                    SectionHeader(title: "settings.section.timer")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)
                    
                    VStack(spacing: 0) {
                        ToggleRow(title: "settings.keepScreenOn", isOn: $keepScreenOn)
                    }
                    .background(theme.surface)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, AppSpacing.large)

                // Section 2: 알림 기본값
                VStack(spacing: 0) {
                    SectionHeader(title: "settings.section.notificationDefaults")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)

                    Text("settings.notification.help")
                        .font(AppFont.caption())
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)

                    VStack(spacing: 0) {
                        HStack {
                            Text("settings.notification.sound")
                                .font(AppFont.body())
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            Menu {
                                ForEach(NotificationSound.allCases, id: \.self) { sound in
                                    Button(action: {
                                        defaultSoundRaw = sound.rawValue
                                        AudioManager.shared.playSound(sound)
                                    }) {
                                        if NotificationSound(rawValue: defaultSoundRaw) == sound {
                                            Label(sound.displayName, systemImage: "checkmark")
                                        } else {
                                            Text(sound.displayName)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(NotificationSound(rawValue: defaultSoundRaw)?.displayName ?? NotificationSound.default.displayName)
                                        .font(AppFont.body())
                                        .foregroundColor(theme.textSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)

                        Divider().padding(.leading, AppSpacing.medium)

                        HStack {
                            Text("settings.notification.vibration")
                                .font(AppFont.body())
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            Menu {
                                ForEach(VibrationPattern.allCases, id: \.self) { pattern in
                                    Button(action: {
                                        defaultVibrationRaw = pattern.rawValue
                                        HapticManager.shared.playVibration(pattern)
                                    }) {
                                        if VibrationPattern(rawValue: defaultVibrationRaw) == pattern {
                                            Label(pattern.displayName, systemImage: "checkmark")
                                        } else {
                                            Text(pattern.displayName)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(VibrationPattern(rawValue: defaultVibrationRaw)?.displayName ?? VibrationPattern.default.displayName)
                                        .font(AppFont.body())
                                        .foregroundColor(theme.textSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                    .background(theme.surface)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, AppSpacing.large)

                // Section 3: 테마
                VStack(spacing: 0) {
                    SectionHeader(title: "settings.section.theme")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)

                    VStack(spacing: 0) {
                        HStack {
                            Text("settings.section.theme")
                                .font(AppFont.body())
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            Menu {
                                ForEach(ThemeSelection.allCases) { option in
                                    Button(action: {
                                        themeStore.selection = option
                                    }) {
                                        if themeStore.selection == option {
                                            Label(LocalizedStringKey(option.displayKey), systemImage: "checkmark")
                                        } else {
                                            Text(LocalizedStringKey(option.displayKey))
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(LocalizedStringKey(themeStore.selection.displayKey))
                                        .font(AppFont.body())
                                        .foregroundColor(theme.textSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                    .background(theme.surface)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, AppSpacing.large)

                // Section 4: 정보
                VStack(spacing: 0) {
                    SectionHeader(title: "settings.section.info")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)
                    
                    VStack(spacing: 0) {
                        StaticRow(title: "settings.appVersion", value: "1.0.0")
                    }
                    .background(theme.surface)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, 40)
            }
        }
        .background(theme.background.ignoresSafeArea(.all))
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Components

struct SectionHeader: View {
    let title: LocalizedStringKey
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.callout())
                .foregroundColor(theme.textPrimary)
            Spacer()
        }
    }
}

struct ToggleRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
    }
}

struct OptionRow: View {
    let title: LocalizedStringKey
    let value: LocalizedStringKey
    let isEnabled: Bool
    let action: () -> Void
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack {
                Text(title)
                    .font(AppFont.body())
                    .foregroundColor(isEnabled ? theme.textPrimary : theme.textSecondary)
                
                Spacer()
                
                Text(value)
                    .font(AppFont.body())
                    .foregroundColor(isEnabled ? theme.accent : theme.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
        }
        .disabled(!isEnabled)
    }
}

struct InfoRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(theme.textPrimary)
            
            Text(description)
                .font(AppFont.caption())
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
    }
}

struct LinkRow: View {
    let title: LocalizedStringKey
    let action: () -> Void
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(theme.accent)
                
                Spacer()
                
            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
        }
    }
}

struct StaticRow: View {
    let title: LocalizedStringKey
    let value: String
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppFont.body())
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeStore())
}
