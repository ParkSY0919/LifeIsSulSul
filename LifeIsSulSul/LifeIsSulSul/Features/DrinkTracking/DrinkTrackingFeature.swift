import SwiftUI
import Foundation
import ComposableArchitecture
import ActivityKit

struct DrinkTrackingFeature: Reducer {
    struct State: Equatable {
        // UI 관련 상태만 유지
        var showRecords = false
        var isSaving = false  // 저장 중 상태
        
        // Session 데이터 스냅샷 (MainActor 격리 문제 해결)
        var sojuShots: Int = 0
        var beerGlasses: Int = 0
        var somaekGlasses: Int = 0
        var isTracking: Bool = false
        var isPaused: Bool = false
        var elapsedTime: TimeInterval = 0
        var startTime: Date? = nil
        var sojuBottles: Int = 0
        var beerBottles: Int = 0
        var sojuFillLevel: CGFloat = 0
        var beerFillLevel: CGFloat = 0
        var somaekFillLevel: CGFloat = 0
        var formattedTime: String = "00분 00초"
        var currentHourlyPace: CurrentHourlyPace = .empty
        
        // SharedDataManager에서 상태 업데이트하는 메서드
        mutating func updateFromSession(_ session: DrinkingSession) {
            self.sojuShots = session.sojuShots
            self.beerGlasses = session.beerGlasses
            self.somaekGlasses = session.somaekGlasses
            self.isTracking = session.isTracking
            self.isPaused = session.isPaused
            self.elapsedTime = session.elapsedTime
            self.startTime = session.startTime
            self.sojuBottles = session.sojuBottles
            self.beerBottles = session.beerBottles
            self.sojuFillLevel = session.sojuFillLevel
            self.beerFillLevel = session.beerFillLevel
            self.somaekFillLevel = session.somaekFillLevel
            self.formattedTime = session.formattedTime
            self.currentHourlyPace = session.currentHourlyPace
        }
    }
    
    enum Action: Equatable {
        case addDrink(DrinkType)
        case startTracking
        case stopTracking
        case resumeTracking
        case saveRecord
        case showRecords
        case hideRecords
        case scenePhaseChanged(ScenePhase)
        case startLiveActivity
        case updateLiveActivity
        case endLiveActivity
        case timerTick
        case savingCompleted
        case savingFailed(String)
        case updateStateFromSession  // 세션 데이터로 상태 업데이트
    }
    
    @Dependency(\.drinkRecordService) var drinkRecordService
    @Dependency(\.continuousClock) var clock
    
    private enum CancelID { case timer }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .addDrink(drinkType):
                // SharedDataManager의 currentSession에 직접 추가
                let sharedManager = SharedDataManager.shared
                switch drinkType {
                case .soju:
                    MainActor.run {
                        sharedManager.addSoju()
                    }
                    
                case .beer:
                    sharedManager.addBeer()
                case .somaek:
                    sharedManager.addSomaek()
                }
                return .none
                
            case .startTracking:
                // SharedDataManager에서 직접 시작
                SharedDataManager.shared.startTracking()
                
                return .run { send in
                    // Live Activity 자동 시작
                        await send(.startLiveActivity)
                    
                    
                    // 타이머 시작
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .stopTracking:
                // SharedDataManager에서 직접 정지
                SharedDataManager.shared.stopTracking()
                
                return .run { send in
                    await send(.updateLiveActivity)
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)
                
            case .resumeTracking:
                // SharedDataManager에서 직접 재시작
                SharedDataManager.shared.resumeTracking()
                
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .timerTick:
                // SharedDataManager의 currentSession에서 시간 업데이트
                SharedDataManager.shared.updateElapsedTime()
                
                let session = SharedDataManager.shared.currentSession
                
                return .run { send in
                    // Live Activity 업데이트 (10초마다)
                    if Int(session.elapsedTime) % 10 == 0 {
                        await send(.updateLiveActivity)
                    }
                }
                
            case .saveRecord:
                // 저장 시작
                state.isSaving = true
                
                let session = SharedDataManager.shared.currentSession
                
                let record = DrinkRecord(
                    date: Date(),
                    sojuBottles: session.sojuBottles,
                    sojuShots: session.sojuShots % 8,
                    beerBottles: session.beerBottles,
                    beerGlasses: session.beerGlasses % 4,
                    somaekGlasses: session.somaekGlasses,
                    hourlyPace: session.hourlyPace,
                    totalDuration: session.elapsedTime
                )
                
                return .run { send in
                    do {
                        // DrinkRecord 저장
                        await drinkRecordService.saveRecord(record)
                        
                        // UserDefaults 저장 (2초 지연)
                        try await SharedDataManager.shared.saveSessionToUserDefaults()
                        
                        // 세션 리셋
                        SharedDataManager.shared.resetSession()
                        
                        // Live Activity 종료
                        await send(.endLiveActivity)
                        
                        await send(.savingCompleted)
                    } catch {
                        await send(.savingFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)
                
            case .savingCompleted:
                state.isSaving = false
                return .none
                
            case .savingFailed(let error):
                state.isSaving = false
                print("DrinkTrackingFeature: Saving failed - \(error)")
                return .none
                
            case .showRecords:
                state.showRecords = true
                return .none
                
            case .hideRecords:
                state.showRecords = false
                return .none
                
            case let .scenePhaseChanged(phase):
                let session = SharedDataManager.shared.currentSession
                switch phase {
                case .background:
                    if session.isTracking {
                        session.backgroundEnterTime = Date()
                    }
                case .active:
                    if session.isTracking, let backgroundTime = session.backgroundEnterTime {
                        let backgroundDuration = Date().timeIntervalSince(backgroundTime)
                        // 백그라운드에서 3분 이상 지났으면 일시정지된 것으로 간주
                        if backgroundDuration > 180 {
                            session.pausedTime += backgroundDuration
                        }
                        session.backgroundEnterTime = nil
                    }
                case .inactive:
                    break
                @unknown default:
                    break
                }
                return .none
                
            case .startLiveActivity:
                    let session = SharedDataManager.shared.currentSession
                    return .run { _ in
                        await DrinkingTimerActivityManager.shared.startActivity(
                            sessionStartTime: session.startTime ?? Date()
                        )
                    }
                
                return .none
                
            case .updateLiveActivity:
                    let session = SharedDataManager.shared.currentSession
                    return .run { _ in
                        await DrinkingTimerActivityManager.shared.updateActivity(
                            isActive: session.isTracking,
                            isPaused: session.isPaused,
                            elapsedTime: session.elapsedTime,
                            sojuBottles: session.sojuBottles,
                            sojuShots: session.sojuShots % 8,
                            beerBottles: session.beerBottles,
                            beerGlasses: session.beerGlasses % 4,
                            somaekGlasses: session.somaekGlasses
                        )
                    }
                
                return .none
                
            case .endLiveActivity:
                    return .run { _ in
                        await DrinkingTimerActivityManager.shared.endActivity()
                    }
                
                return .none
            }
        }
    }
}
