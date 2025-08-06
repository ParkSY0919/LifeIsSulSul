import SwiftUI
import Foundation
import ComposableArchitecture

struct DrinkTrackingFeature: Reducer {
    struct State: Equatable {
        var sojuShots = 0
        var beerGlasses = 0
        var somaekGlasses = 0
        var isTracking = false
        var isPaused = false
        var elapsedTime: TimeInterval = 0
        var hourlyPace: [HourlyRecord] = []
        var currentHourlyPace: CurrentHourlyPace = .empty
        var showRecords = false
        
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
                return .none
                
            case .startTracking:
                state.isTracking = true
                state.isPaused = false
                state.elapsedTime = 0
                state.hourlyPace = []
                
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .stopTracking:
                state.isTracking = false
                state.isPaused = true
                return .cancel(id: CancelID.timer)
                
            case .resumeTracking:
                state.isTracking = true
                state.isPaused = false
                
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .timerTick:
                guard state.isTracking else { return .none }
                
                state.elapsedTime += 1
                
                // 매 시간마다 hourly pace 기록
                if Int(state.elapsedTime) % 3600 == 0 && state.elapsedTime > 0 {
                    return .send(.hourlyTick)
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
                state.sojuShots = 0
                state.beerGlasses = 0
                state.somaekGlasses = 0
                state.isTracking = false
                state.isPaused = false
                state.elapsedTime = 0
                state.hourlyPace = []
                state.currentHourlyPace = .empty
                
                return .cancel(id: CancelID.timer)
                
            case .showRecords:
                state.showRecords = true
                return .none
                
            case .hideRecords:
                state.showRecords = false
                return .none
                
            case .updateCurrentPace:
                // 현재 진행 중인 시간의 페이스 업데이트
                return .none
            }
        }
    }
}