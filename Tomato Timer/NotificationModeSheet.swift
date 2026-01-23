
import SwiftUI

struct NotificationModeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var notificationMode: NotificationMode = .sound
    @State private var selectedSound: NotificationSound = .default
    @State private var selectedVibration: VibrationPattern = .default
    
    @State private var showSoundSelection = false
    @State private var showVibrationSelection = false
    
    var onStart: () -> Void
    
    enum NotificationMode {
        case sound
        case vibration
    }
    
    enum NotificationSound: String, CaseIterable {
        case `default` = "기본"
        case short = "짧은 알림"
        case soft = "부드러운 알림"
    }
    
    enum VibrationPattern: String, CaseIterable {
        case `default` = "기본"
        case short = "짧은 진동"
        case double = "두 번 진동"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text("알림 방식")
                    .font(AppFont.title())
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.medium)
            
            // Section 1: Notification Mode
            VStack(spacing: 0) {
                // Sound option
                Button(action: {
                    notificationMode = .sound
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: notificationMode == .sound ? "record.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(notificationMode == .sound ? AppColor.primary : AppColor.textSecondary)
                        
                        Text("소리")
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.smallPlus)
                }
                
                Divider()
                    .padding(.leading, AppSpacing.medium)
                
                // Vibration option
                Button(action: {
                    notificationMode = .vibration
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: notificationMode == .vibration ? "record.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(notificationMode == .vibration ? AppColor.primary : AppColor.textSecondary)
                        
                        Text("진동")
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.smallPlus)
                }
            }
            .background(Color.white)
            .cornerRadius(AppRadius.button)
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.bottom, AppSpacing.medium)
            
            // Section 2 & 3: Sound or Vibration selection
            if notificationMode == .sound {
                // Sound selection row
                VStack(spacing: 0) {
                    Button(action: {
                        showSoundSelection = true
                    }) {
                        HStack {
                            Text("알림음")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            
                            Spacer()
                            
                            Text(selectedSound.rawValue)
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textSecondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColor.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                }
                .background(Color.white)
                .cornerRadius(AppRadius.button)
                .padding(.horizontal, AppSpacing.mediumPlus)
                .padding(.bottom, AppSpacing.medium)
            } else {
                // Vibration selection row
                VStack(spacing: 0) {
                    Button(action: {
                        showVibrationSelection = true
                    }) {
                        HStack {
                            Text("진동 패턴")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            
                            Spacer()
                            
                            Text(selectedVibration.rawValue)
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textSecondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColor.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                }
                .background(Color.white)
                .cornerRadius(AppRadius.button)
                .padding(.horizontal, AppSpacing.mediumPlus)
                .padding(.bottom, AppSpacing.medium)
            }
            
            Spacer()
            
            // Start button
            Button(action: {
                onStart()
                dismiss()
            }) {
                Text("시작")
                    .font(AppFont.button())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColor.primary)
                    .cornerRadius(AppRadius.button)
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.bottom, AppSpacing.large)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSoundSelection) {
            SoundSelectionSheet(selectedSound: $selectedSound)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showVibrationSelection) {
            VibrationSelectionSheet(selectedVibration: $selectedVibration)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Sound Selection Sheet

struct SoundSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSound: NotificationModeSheet.NotificationSound
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text("알림음 선택")
                    .font(AppFont.title())
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.medium)
            
            // Sound options
            VStack(spacing: 0) {
                ForEach(NotificationModeSheet.NotificationSound.allCases, id: \.self) { sound in
                    Button(action: {
                        // Play sound preview
                        playSound(sound)
                        
                        // Update selection
                        selectedSound = sound
                        
                        // Dismiss sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }) {
                        HStack {
                            Text(sound.rawValue)
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            
                            Spacer()
                            
                            if selectedSound == sound {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColor.primary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                    
                    if sound != NotificationModeSheet.NotificationSound.allCases.last {
                        Divider()
                            .padding(.leading, AppSpacing.medium)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(AppRadius.button)
            .padding(.horizontal, AppSpacing.mediumPlus)
            
            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .preferredColorScheme(.light)
    }
    
    private func playSound(_ sound: NotificationModeSheet.NotificationSound) {
        // TODO: Implement actual sound playback
        print("Playing sound: \(sound.rawValue)")
    }
}

// MARK: - Vibration Selection Sheet

struct VibrationSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVibration: NotificationModeSheet.VibrationPattern
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text("진동 패턴 선택")
                    .font(AppFont.title())
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.medium)
            
            // Vibration options
            VStack(spacing: 0) {
                ForEach(NotificationModeSheet.VibrationPattern.allCases, id: \.self) { pattern in
                    Button(action: {
                        // Trigger vibration preview
                        triggerVibration(pattern)
                        
                        // Update selection
                        selectedVibration = pattern
                        
                        // Dismiss sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }) {
                        HStack {
                            Text(pattern.rawValue)
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            
                            Spacer()
                            
                            if selectedVibration == pattern {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColor.primary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                    
                    if pattern != NotificationModeSheet.VibrationPattern.allCases.last {
                        Divider()
                            .padding(.leading, AppSpacing.medium)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(AppRadius.button)
            .padding(.horizontal, AppSpacing.mediumPlus)
            
            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .preferredColorScheme(.light)
    }
    
    private func triggerVibration(_ pattern: NotificationModeSheet.VibrationPattern) {
        // TODO: Implement actual vibration patterns
        print("Triggering vibration: \(pattern.rawValue)")
        
        // Basic vibration feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if pattern == .double {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.impactOccurred()
            }
        }
    }
}

#Preview {
    NotificationModeSheet(onStart: {
        print("Start timer")
    })
}
