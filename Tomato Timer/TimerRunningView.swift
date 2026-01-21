import SwiftUI

struct TimerRunningView: View {
    @Environment(\.dismiss) var dismiss
    
    // Mock Data State
    @State private var timeRemaining: String = "04:32"
    @State private var isScreenOn: Bool = true
    @State private var isPaused: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Central Card
                    VStack(spacing: 20) {
                        // Title "근로 준비" removed as requested
                        
                        Text("커피 내리기")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.top, 30) // Balanced padding
                        
                        Text(timeRemaining)
                            .font(.system(size: 80, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColor.primary)
                            .padding(.vertical, 10)
                            .minimumScaleFactor(0.5)
                        
                        Text("다음 Step: 휴식 (10분)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                    }
                    .padding(AppSpacing.mediumPlus) // 20
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
                    .padding(.horizontal, AppSpacing.mediumPlus) // 20
                    
                    // Options below card
                    VStack(spacing: 20) {
                        Toggle("화면 켜짐 유지", isOn: $isScreenOn)
                            .toggleStyle(SwitchToggleStyle(tint: AppColor.primary))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.gray)
                            Text("알림 모드: 진동+소리")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, AppSpacing.mediumPlus) // 20
                    
                    Spacer()
                    
                    // Bottom Controls
                    HStack(spacing: 40) {
                        // Stop Button (Destructive - Left)
                        VStack(spacing: 8) {
                            Button(action: {
                                dismiss()
                            }) {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "stop.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.red)
                                    )
                            }
                            Text("정지")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        // Pause/Play Button (Primary - Center)
                        VStack(spacing: 8) {
                            Button(action: {
                                isPaused.toggle()
                            }) {
                                Circle()
                                    .fill(AppColor.primary)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: AppColor.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                            .font(.system(size: 32, weight: .bold)) // Slightly bolder
                                            .foregroundColor(.white)
                                            .offset(x: isPaused ? 2 : 0) // Optical centering for play icon
                                    )
                            }
                            Text(isPaused ? "재생" : "일시정지")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColor.primary)
                        }
                        .padding(.bottom, 20) // Push up slightly to emphasize center
                        
                        // Next Button (Secondary - Right)
                        VStack(spacing: 8) {
                            Button(action: {
                                // Next Step Logic
                            }) {
                                Circle()
                                    .fill(Color(UIColor.systemGray6))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.gray)
                                    )
                            }
                            Text("다음")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("근로 준비")
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
        }
    }
}

#Preview {
    TimerRunningView()
}
