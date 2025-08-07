import SwiftUI
import Foundation
import ComposableArchitecture
import ActivityKit

struct DrinkTrackingFeature: Reducer {
    struct State: Equatable {
        var sojuShots = 0
        var beerGlasses = 0
        var somaekGlasses = 0
        var isTracking = false
        var isPaused = false
        var elapsedTime: TimeInterval = 0
        var startTime: Date?
        var pausedTime: TimeInterval = 0
        var hourlyPace: [HourlyRecord] = []
        var currentHourlyPace: CurrentHourlyPace = .empty
        var showRecords = false
        var lastSaveTime: Date?
        var backgroundEnterTime: Date?
        var isLiveActivityEnabled = false
        
        // 계산된 속성들
        var sojuBottles: Int { sojuShots / 8 }
        var beerBottles: Int { beerGlasses / 4 }
        var sojuFillLevel: CGFloat { CGFloat(sojuShots % 8) / 8.0 }
        var beerFillLevel: CGFloat { CGFloat(beerGlasses % 4) / 4.0 }
        var somaekFillLevel: CGFloat { CGFloat(somaekGlasses % 10) / 10.0 }
        
        var formattedTime: String {
            let hours = Int(elapsedTime) / 3600
            let minutes = (Int(elapsedTime) % 3600) / 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%d시간 %02d분 %02d초", hours, minutes, seconds)
        }
    }
    
    enum Action: Equatable {
        case addDrink(DrinkType)
        case startTracking
        case stopTracking
        case resumeTracking
        case saveRecord
        case resetState
        case timerTick
        case hourlyTick
        case showRecords
        case hideRecords
        case updateCurrentPace
        case scenePhaseChanged(ScenePhase)
        case autoSave
        case calculateElapsedTime
        case startLiveActivity
        case updateLiveActivity
        case endLiveActivity
        case toggleLiveActivityPermission
    }
    
    @Dependency(\.drinkRecordService) var drinkRecordService
    @Dependency(\.continuousClock) var clock
    
    private enum CancelID { case timer }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .addDrink(drinkType):
                guard state.isTracking else { return .none }
                
                switch drinkType {
                case .soju:
                    state.sojuShots += 1
                case .beer:
                    state.beerGlasses += 1
                case .somaek:
                    state.somaekGlasses += 1
                }
                
                if state.isLiveActivityEnabled {
                    return .send(.updateLiveActivity)
                }
                return .none
                
            case .startTracking:
                state.isTracking = true
                state.isPaused = false
                state.elapsedTime = 0
                state.startTime = Date()
                state.pausedTime = 0
                state.hourlyPace = []
                state.lastSaveTime = Date()
                
                return .run { send in
                    // Start Live Activity if enabled
                    if #available(iOS 16.1, *) {
                        await send(.startLiveActivity)
                    }
                    
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .stopTracking:
                state.isTracking = false
                state.isPaused = true
                
                // 정확한 시간 계산
                if let startTime = state.startTime {
                    let currentTime = Date()
                    state.elapsedTime = currentTime.timeIntervalSince(startTime) - state.pausedTime
                }
                
                return .run { [state] send in
                    if state.isLiveActivityEnabled {
                        await send(.updateLiveActivity)
                    }
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)
                
            case .resumeTracking:
                let pauseStartTime = state.backgroundEnterTime ?? Date()
                let pauseDuration = Date().timeIntervalSince(pauseStartTime)
                state.pausedTime += pauseDuration
                
                state.isTracking = true
                state.isPaused = false
                state.backgroundEnterTime = nil
                
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .timerTick:
                guard state.isTracking, let startTime = state.startTime else { return .none }
                
                // 정확한 시간 계산
                let currentTime = Date()
                state.elapsedTime = currentTime.timeIntervalSince(startTime) - state.pausedTime
                
                // 매 시간마다 hourly pace 기록
                if Int(state.elapsedTime) % 3600 == 0 && state.elapsedTime > 0 {
                    return .send(.hourlyTick)
                }
                
                // 5분마다 자동 저장
                if let lastSave = state.lastSaveTime, 
                   Date().timeIntervalSince(lastSave) >= 300 {
                    return .send(.autoSave)
                }
                
                // Live Activity 업데이트 (30초마다)
                if state.isLiveActivityEnabled && Int(state.elapsedTime) % 30 == 0 {
                    return .send(.updateLiveActivity)
                }
                
                return .none
                
            case .hourlyTick:
                let hourRecord = HourlyRecord(
                    hour: state.hourlyPace.count + 1,
                    sojuBottles: state.sojuBottles,
                    sojuShots: state.sojuShots % 8,
                    beerBottles: state.beerBottles,
                    beerGlasses: state.beerGlasses % 4,
                    somaekGlasses: state.somaekGlasses
                )
                
                state.hourlyPace.append(hourRecord)
                state.currentHourlyPace = CurrentHourlyPace(from: hourRecord)
                
                return .none
                
            case .saveRecord:
                // 마지막 시간 기록 추가
                if state.elapsedTime > Double(state.hourlyPace.count * 3600) {
                    let finalRecord = HourlyRecord(
                        hour: state.hourlyPace.count + 1,
                        sojuBottles: state.sojuBottles,
                        sojuShots: state.sojuShots % 8,
                        beerBottles: state.beerBottles,
                        beerGlasses: state.beerGlasses % 4,
                        somaekGlasses: state.somaekGlasses
                    )
                    state.hourlyPace.append(finalRecord)
                }
                
                let record = DrinkRecord(
                    date: Date(),
                    sojuBottles: state.sojuBottles,
                    sojuShots: state.sojuShots % 8,
                    beerBottles: state.beerBottles,
                    beerGlasses: state.beerGlasses % 4,
                    somaekGlasses: state.somaekGlasses,
                    hourlyPace: state.hourlyPace,
                    totalDuration: state.elapsedTime
                )
                
                return .run { send in
                    await drinkRecordService.saveRecord(record)
                    await send(.resetState)
                }
                
            case .resetState:
                let shouldEndLiveActivity = state.isLiveActivityEnabled
                
                state.sojuShots = 0
                state.beerGlasses = 0
                state.somaekGlasses = 0
                state.isTracking = false
                state.isPaused = false
                state.elapsedTime = 0
                state.startTime = nil
                state.pausedTime = 0
                state.hourlyPace = []
                state.currentHourlyPace = .empty
                state.lastSaveTime = nil
                state.backgroundEnterTime = nil
                state.isLiveActivityEnabled = false
                
                return .run { send in
                    if shouldEndLiveActivity {
                        await send(.endLiveActivity)
                    }
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)
                
            case .showRecords:
                state.showRecords = true
                return .none
                
            case .hideRecords:
                state.showRecords = false
                return .none
                
            case .updateCurrentPace:
                // 현재 진행 중인 시간의 페이스 업데이트
                return .none
                
            case let .scenePhaseChanged(phase):
                switch phase {
                case .background:
                    if state.isTracking {
                        state.backgroundEnterTime = Date()
                    }
                case .active:
                    if state.isTracking, let backgroundTime = state.backgroundEnterTime {
                        let backgroundDuration = Date().timeIntervalSince(backgroundTime)
                        // 백그라운드에서 3분 이상 지났으면 일시정지된 것으로 간주
                        if backgroundDuration > 180 {
                            state.pausedTime += backgroundDuration
                        }
                        state.backgroundEnterTime = nil
                    }
                case .inactive:
                    break
                @unknown default:
                    break
                }
                return .none
                
            case .autoSave:
                state.lastSaveTime = Date()
                
                let tempRecord = DrinkRecord(
                    date: Date(),
                    sojuBottles: state.sojuBottles,
                    sojuShots: state.sojuShots % 8,
                    beerBottles: state.beerBottles,
                    beerGlasses: state.beerGlasses % 4,
                    somaekGlasses: state.somaekGlasses,
                    hourlyPace: state.hourlyPace,
                    totalDuration: state.elapsedTime
                )
                
                return .run { _ in
                    await drinkRecordService.saveTempRecord(tempRecord)
                }
                
            case .calculateElapsedTime:
                guard let startTime = state.startTime else { return .none }
                let currentTime = Date()
                state.elapsedTime = currentTime.timeIntervalSince(startTime) - state.pausedTime
                return .none
                
            case .startLiveActivity:
                if #available(iOS 16.1, *) {
                    state.isLiveActivityEnabled = true
                    
                    return .run { [state] _ in
                        await DrinkingTimerActivityManager.shared.startActivity(
                            sessionStartTime: state.startTime ?? Date()
                        )
                    }
                }
                return .none
                
            case .updateLiveActivity:
                if #available(iOS 16.1, *), state.isLiveActivityEnabled {
                    return .run { [state] _ in
                        await DrinkingTimerActivityManager.shared.updateActivity(
                            isActive: state.isTracking,
                            isPaused: state.isPaused,
                            elapsedTime: state.elapsedTime,
                            sojuBottles: state.sojuBottles,
                            sojuShots: state.sojuShots % 8,
                            beerBottles: state.beerBottles,
                            beerGlasses: state.beerGlasses % 4,
                            somaekGlasses: state.somaekGlasses
                        )
                    }
                }
                return .none
                
            case .endLiveActivity:
                if #available(iOS 16.1, *) {
                    state.isLiveActivityEnabled = false
                    
                    return .run { _ in
                        await DrinkingTimerActivityManager.shared.endActivity()
                    }
                }
                return .none
                
            case .toggleLiveActivityPermission:
                if #available(iOS 16.1, *) {
                    return .run { send in
                        let authInfo = ActivityAuthorizationInfo()
                        if authInfo.areActivitiesEnabled {
                            await send(.startLiveActivity)
                        } else {
                            await send(.endLiveActivity)
                        }
                    }
                }
                return .none
            }
        }
    }
}
