
import SwiftUI

struct SettingsView: View {
    // Settings State
    @AppStorage("keepScreenOn") private var keepScreenOn = false
    @AppStorage("defaultNotificationSound") private var defaultSoundRaw: String = NotificationSound.default.rawValue
    @AppStorage("defaultNotificationVibration") private var defaultVibrationRaw: String = VibrationPattern.default.rawValue
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Content starts with first section
                // Section 1: 타이머
                VStack(spacing: 0) {
                    SectionHeader(title: "타이머")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)
                    
                    VStack(spacing: 0) {
                        ToggleRow(
                            title: "타이머 실행 중 화면 켜짐 유지",
                            isOn: $keepScreenOn
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, AppSpacing.large)

                // Section 2: 알림 기본값
                VStack(spacing: 0) {
                    SectionHeader(title: "알림 기본값")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)

                    Text("알림음과 진동 패턴은 앱이 켜져 있을 때만 적용돼요.")
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)

                    VStack(spacing: 0) {
                        HStack {
                            Text("알림음")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            Spacer()
                            Menu {
                                ForEach(NotificationSound.allCases, id: \.self) { sound in
                                    Button(action: {
                                        defaultSoundRaw = sound.rawValue
                                        AudioManager.shared.playSound(sound)
                                    }) {
                                        if NotificationSound(rawValue: defaultSoundRaw) == sound {
                                            Label(sound.rawValue, systemImage: "checkmark")
                                        } else {
                                            Text(sound.rawValue)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(NotificationSound(rawValue: defaultSoundRaw)?.rawValue ?? NotificationSound.default.rawValue)
                                        .font(AppFont.body())
                                        .foregroundColor(AppColor.textSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColor.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)

                        Divider().padding(.leading, AppSpacing.medium)

                        HStack {
                            Text("진동 패턴")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            Spacer()
                            Menu {
                                ForEach(VibrationPattern.allCases, id: \.self) { pattern in
                                    Button(action: {
                                        defaultVibrationRaw = pattern.rawValue
                                        HapticManager.shared.playVibration(pattern)
                                    }) {
                                        if VibrationPattern(rawValue: defaultVibrationRaw) == pattern {
                                            Label(pattern.rawValue, systemImage: "checkmark")
                                        } else {
                                            Text(pattern.rawValue)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(VibrationPattern(rawValue: defaultVibrationRaw)?.rawValue ?? VibrationPattern.default.rawValue)
                                        .font(AppFont.body())
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
                    .background(Color.white)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, AppSpacing.large)
                
                // Section 3: 정보
                VStack(spacing: 0) {
                    SectionHeader(title: "정보")
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, AppSpacing.small)
                    
                    VStack(spacing: 0) {
                        StaticRow(
                            title: "앱 버전",
                            value: "1.0.0"
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea(.all))
        .preferredColorScheme(.light)
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Components

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.callout())
                .foregroundColor(AppColor.textPrimary)
            Spacer()
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(AppColor.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
    }
}

struct OptionRow: View {
    let title: String
    let value: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack {
                Text(title)
                    .font(AppFont.body())
                    .foregroundColor(isEnabled ? AppColor.textPrimary : AppColor.textSecondary)
                
                Spacer()
                
                Text(value)
                    .font(AppFont.body())
                    .foregroundColor(isEnabled ? AppColor.primary : AppColor.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
        }
        .disabled(!isEnabled)
    }
}

struct InfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(AppColor.textPrimary)
            
            Text(description)
                .font(AppFont.caption())
                .foregroundColor(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
    }
}

struct LinkRow: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppFont.body())
                    .foregroundColor(AppColor.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
        }
    }
}

struct StaticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundColor(AppColor.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
    }
}

#Preview {
    SettingsView()
}
