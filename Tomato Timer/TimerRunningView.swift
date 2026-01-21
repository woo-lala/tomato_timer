import SwiftUI

struct TimerRunningView: View {
    @Environment(\.dismiss) var dismiss
    
    // Mock Data State
    @State private var timeRemaining: String = "04:32"
    @State private var isScreenOn: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
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
                    HStack(spacing: 16) {
                        // Next Button (Neutral)
                        Button(action: {
                            // Next Step
                        }) {
                            Text("다음")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(AppRadius.standard) // 16
                        }
                        
                        // Pause Button (Primary)
                        Button(action: {
                            // Pause
                        }) {
                            Text("일시정지")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AppColor.primary)
                                .cornerRadius(AppRadius.standard) // 16
                        }
                        
                        // Stop Button (Red)
                        Button(action: {
                            dismiss()
                        }) {
                            Text("정지")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.mdDestructive)
                                .cornerRadius(AppRadius.standard) // 16
                        }
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus) // 20
                    .padding(.bottom, 40)
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
