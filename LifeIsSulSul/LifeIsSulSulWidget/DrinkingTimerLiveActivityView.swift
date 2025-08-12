import SwiftUI
import ActivityKit
import WidgetKit

struct DrinkingTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DrinkingTimerActivity.self) { context in
            // Lock Screen View
            DrinkingTimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Text(context.state.statusIcon)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("음주 타이머")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(context.state.formattedElapsedTime)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        if !context.state.drinkingSummary.isEmpty && context.state.drinkingSummary != "음주 기록 없음" {
                            Text(context.state.drinkingSummary)
                                .font(.caption)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                        } else {
                            Text("기록을 시작하세요")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        // Pause/Resume Button
                        Button(intent: DrinkingTimerToggleIntent()) {
                            HStack {
                                Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                Text(context.state.isPaused ? "재시작" : "일시정지")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Quick Add Buttons
                        HStack(spacing: 8) {
                            Button(intent: AddSojuIntent()) {
                                Text("+소주")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(intent: AddBeerIntent()) {
                                Text("+맥주")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(intent: AddSomaekIntent()) {
                                Text("+소맥")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Save Button
                        Button(intent: SaveRecordIntent()) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("저장")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
            } compactLeading: {
                // Compact Leading View - 상태 아이콘과 간단한 정보
                HStack(spacing: 4) {
                    Text(context.state.statusIcon)
                        .font(.system(size: 14))
                    if context.state.sojuBottles + context.state.beerBottles + context.state.somaekGlasses > 0 {
                        Text("\(context.state.sojuBottles + context.state.beerBottles + context.state.somaekGlasses)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            } compactTrailing: {
                // Compact Trailing View - 타이머
                Text(context.state.formattedElapsedTime)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(context.state.isActive ? .primary : .secondary)
            } minimal: {
                // Minimal View - 상태만 표시
                Text(context.state.statusIcon)
                    .font(.system(size: 16))
                    .foregroundColor(context.state.isActive ? .primary : .secondary)
            }
        }
    }
}

struct DrinkingTimerLockScreenView: View {
    let context: ActivityViewContext<DrinkingTimerActivity>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(context.state.statusIcon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("🍻 LifeIsSulSul")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("음주 기록 중 • \(context.state.formattedElapsedTime) 경과")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 음주량 정보
            if !context.state.drinkingSummary.isEmpty && context.state.drinkingSummary != "음주 기록 없음" {
                Text(context.state.drinkingSummary)
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.vertical, 4)
            } else {
                Text("아직 기록된 음주량이 없습니다")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 4)
            }
            
            // 제어 버튼들 - 컴팩트한 디자인
            VStack(spacing: 8) {
                // 상단: 타이머 제어
                HStack(spacing: 8) {
                    Button(intent: DrinkingTimerToggleIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                .font(.caption2)
                            Text(context.state.isPaused ? "재시작" : "정지")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(intent: SaveRecordIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.caption2)
                            Text("저장")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            
                // 하단: 빠른 추가 버튼들
                HStack(spacing: 6) {
                    Button(intent: AddSojuIntent()) {
                        Text("+소주")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(intent: AddBeerIntent()) {
                        Text("+맥주")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(intent: AddSomaekIntent()) {
                        Text("+소맥")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(intent: OpenAppIntent()) {
                        Text("앱 열기")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
    }
}
