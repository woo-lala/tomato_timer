
import SwiftUI

struct SettingsView: View {
    // Settings State
    @AppStorage("keepScreenOn") private var keepScreenOn = false
    @AppStorage("defaultNotificationSound") private var defaultSoundRaw: String = NotificationSound.default.rawValue
    @AppStorage("defaultNotificationVibration") private var defaultVibrationRaw: String = VibrationPattern.default.rawValue
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.themePalette) private var theme
    @State private var isPrivacyInfoPresented = false
    
    
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

                // Section 4: 개인정보
                VStack(spacing: 0) {
                    SectionHeader(title: "settings.section.privacy")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)

                    VStack(spacing: 0) {
                        LinkRow(title: "settings.privacy.dataCollection", systemImage: "arrow.up.right.square") {
                            isPrivacyInfoPresented = true
                        }
                    }
                    .background(theme.surface)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, AppSpacing.large)

                // Section 5: 정보
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
        .sheet(isPresented: $isPrivacyInfoPresented) {
            PrivacyInfoSheet()
        }
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
    let systemImage: String
    let action: () -> Void
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(theme.accent)
                
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.accent)
                
                Spacer()
        }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
        }
    }
}

struct PrivacyInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text("settings.privacy.dataCollection.title")
                        .font(AppFont.heading())
                        .foregroundColor(theme.textPrimary)

                    PrivacySection(
                        title: "settings.privacy.section1.title",
                        description: "settings.privacy.section1.body",
                        items: [
                            "settings.privacy.section1.item1",
                            "settings.privacy.section1.item2",
                            "settings.privacy.section1.item3",
                            "settings.privacy.section1.item4"
                        ]
                    )

                    PrivacySection(
                        title: "settings.privacy.section2.title",
                        description: "settings.privacy.section2.body",
                        items: [
                            "settings.privacy.section2.item1",
                            "settings.privacy.section2.item2",
                            "settings.privacy.section2.item3",
                            "settings.privacy.section2.item4"
                        ]
                    )

                    PrivacySection(
                        title: "settings.privacy.section3.title",
                        description: "settings.privacy.section3.body",
                        items: [
                            "settings.privacy.section3.item1",
                            "settings.privacy.section3.item2",
                            "settings.privacy.section3.item3"
                        ]
                    )

                    PrivacySection(
                        title: "settings.privacy.section4.title",
                        description: "settings.privacy.section4.body",
                        items: [
                            "settings.privacy.section4.item1",
                            "settings.privacy.section4.item2"
                        ]
                    )

                    PrivacySection(
                        title: "settings.privacy.section5.title",
                        description: "settings.privacy.section5.body",
                        items: [
                            "settings.privacy.section5.item1",
                            "settings.privacy.section5.item2"
                        ]
                    )

                    PrivacySection(
                        title: "settings.privacy.section6.title",
                        description: "settings.privacy.section6.body",
                        items: [
                            "settings.privacy.section6.item1",
                            "settings.privacy.section6.item2",
                            "settings.privacy.section6.item3"
                        ]
                    )

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.mediumPlus)
            }
            .background(theme.background.ignoresSafeArea(.all))
            .navigationTitle("settings.privacy.sheetTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("common.done")
                            .font(AppFont.body())
                            .foregroundColor(theme.accent)
                    }
                }
            }
        }
    }
}

private struct PrivacySection: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let items: [LocalizedStringKey]
    @Environment(\.themePalette) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(AppFont.callout())
                .foregroundColor(theme.textPrimary)

            Text(description)
                .font(AppFont.body())
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, key in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(AppFont.body())
                            .foregroundColor(theme.textSecondary)
                        Text(key)
                            .font(AppFont.body())
                            .foregroundColor(theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
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
