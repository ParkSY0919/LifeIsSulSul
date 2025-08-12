import Foundation
import Combine
import UIKit
import SwiftUI
import os.log

@MainActor
class SharedDataManager: ObservableObject {
    nonisolated(unsafe) static let shared = SharedDataManager()
    
    // Memory-based current session - 메모리에서만 관리
    @Published var currentSession = DrinkingSession()
    
    // LiveActivity 업데이트 콜백
    var onSessionChanged: ((DrinkingSession) -> Void)?
    
    // 저장용 UserDefaults (저장시에만 사용)
    private let suiteName = "group.LifeIsSulSul"
    private var userDefaults: UserDefaults?
    
    private init() {
        setupUserDefaults()
        setupSessionObserver()
        print("SharedDataManager: Initialized with memory-based session")
    }
    
    private func setupUserDefaults() {
        // UserDefaults 설정 (저장용)
        if let appGroupDefaults = UserDefaults(suiteName: suiteName) {
            userDefaults = appGroupDefaults
            print("SharedDataManager: App Group UserDefaults ready")
        } else {
            userDefaults = UserDefaults.standard
            print("SharedDataManager: Using standard UserDefaults as fallback")
        }
    }
    
    private func setupSessionObserver() {
        // currentSession 변경시 콜백 트리거
        $currentSession
            .removeDuplicates { prev, curr in
                prev.sojuShots == curr.sojuShots &&
                prev.beerGlasses == curr.beerGlasses &&
                prev.somaekGlasses == curr.somaekGlasses &&
                prev.isTracking == curr.isTracking &&
                prev.isPaused == curr.isPaused
            }
            .sink { [weak self] session in
                print("SharedDataManager: Session changed, triggering LiveActivity update")
                self?.onSessionChanged?(session)
            }
            .store(in: &cancellables)
        
        // UserDefaults 변경 감지 (Widget에서 변경한 경우)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.syncFromUserDefaults()
            }
            .store(in: &cancellables)
    }
    
    private func syncFromUserDefaults() {
        guard let defaults = userDefaults else { return }
        
        let lastUpdateTime = defaults.object(forKey: "SharedData_lastUpdateTime") as? Date ?? Date.distantPast
        
        // 최근 5초 내 변경인 경우에만 동기화 (Widget에서 변경된 경우)
        if Date().timeIntervalSince(lastUpdateTime) < 5.0 {
            let newSojuShots = defaults.integer(forKey: "SharedData_sojuShots")
            let newSojuBottles = defaults.integer(forKey: "SharedData_sojuBottles")
            let newBeerGlasses = defaults.integer(forKey: "SharedData_beerGlasses") 
            let newBeerBottles = defaults.integer(forKey: "SharedData_beerBottles")
            let newSomaekGlasses = defaults.integer(forKey: "SharedData_somaekGlasses")
            let newIsTracking = defaults.bool(forKey: "SharedData_isTracking")
            let newIsPaused = defaults.bool(forKey: "SharedData_isPaused")
            
            // 메모리 세션과 다른 경우에만 업데이트
            let totalNewSojuShots = (newSojuBottles * 8) + newSojuShots
            let totalNewBeerGlasses = (newBeerBottles * 4) + newBeerGlasses
            
            if totalNewSojuShots != currentSession.sojuShots ||
               totalNewBeerGlasses != currentSession.beerGlasses ||
               newSomaekGlasses != currentSession.somaekGlasses ||
               newIsTracking != currentSession.isTracking ||
               newIsPaused != currentSession.isPaused {
                
                print("SharedDataManager: Syncing from UserDefaults - Widget changes detected")
                
                currentSession.sojuShots = totalNewSojuShots
                currentSession.beerGlasses = totalNewBeerGlasses
                currentSession.somaekGlasses = newSomaekGlasses
                currentSession.isTracking = newIsTracking
                currentSession.isPaused = newIsPaused
            }
        }
    }
    
    nonisolated(unsafe) private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
        print("SharedDataManager: Deinitialized")
    }
    
    // MARK: - Memory-based Actions (즉시 반응)
    
    func addSoju() {
        guard currentSession.isTracking else { 
            print("SharedDataManager: addSoju called but not tracking")
            return 
        }
        currentSession.addSoju()
    }
    
    func addBeer() {
        guard currentSession.isTracking else { 
            print("SharedDataManager: addBeer called but not tracking")
            return 
        }
        currentSession.addBeer()
    }
    
    func addSomaek() {
        guard currentSession.isTracking else { 
            print("SharedDataManager: addSomaek called but not tracking")
            return 
        }
        currentSession.addSomaek()
    }
    
    func startTracking() {
        currentSession.startTracking()
    }
    
    func stopTracking() {
        currentSession.stopTracking()
    }
    
    func resumeTracking() {
        currentSession.resumeTracking()
    }
    
    func toggleTimer() {
        if currentSession.isTracking {
            currentSession.stopTracking()
        } else if currentSession.isPaused {
            currentSession.resumeTracking()
        }
    }
    
    func updateElapsedTime() {
        currentSession.updateElapsedTime()
    }
    
    // MARK: - Save to UserDefaults (저장시에만 사용)
    
    func saveSessionToUserDefaults() async throws {
        print("SharedDataManager: Starting save to UserDefaults...")
        
        guard let defaults = userDefaults else {
            throw SaveError.userDefaultsNotAvailable
        }
        
        // 2초 지연으로 안전한 저장
        try await Task.sleep(for: .seconds(2.0))
        
        let session = currentSession
        
        // UserDefaults에 저장
        defaults.set(session.isTracking, forKey: "SharedData_isTracking")
        defaults.set(session.isPaused, forKey: "SharedData_isPaused")
        defaults.set(session.elapsedTime, forKey: "SharedData_elapsedTime")
        defaults.set(session.sojuBottles, forKey: "SharedData_sojuBottles")
        defaults.set(session.sojuShots % 8, forKey: "SharedData_sojuShots")
        defaults.set(session.beerBottles, forKey: "SharedData_beerBottles")
        defaults.set(session.beerGlasses % 4, forKey: "SharedData_beerGlasses")
        defaults.set(session.somaekGlasses, forKey: "SharedData_somaekGlasses")
        defaults.set(session.pausedTime, forKey: "SharedData_pausedTime")
        defaults.set(Date(), forKey: "SharedData_lastUpdateTime")
        
        if let startTime = session.startTime {
            defaults.set(startTime, forKey: "SharedData_startTime")
        } else {
            defaults.removeObject(forKey: "SharedData_startTime")
        }
        
        // 동기화
        defaults.synchronize()
        
        print("SharedDataManager: Successfully saved session to UserDefaults")
    }
    
    func resetSession() {
        currentSession.reset()
        print("SharedDataManager: Session reset completed")
    }
    
    // MARK: - Error Types
    
    enum SaveError: Error {
        case userDefaultsNotAvailable
    }
    
    // MARK: - Legacy Compatibility (기존 코드 호환용 - 점진적 제거 예정)
    
    // 기존 Published 프로퍼티들을 currentSession으로 연결
    var isTracking: Bool { currentSession.isTracking }
    var isPaused: Bool { currentSession.isPaused }
    var elapsedTime: TimeInterval { currentSession.elapsedTime }
    var sojuBottles: Int { currentSession.sojuBottles }
    var sojuShots: Int { currentSession.sojuShots % 8 }
    var beerBottles: Int { currentSession.beerBottles }
    var beerGlasses: Int { currentSession.beerGlasses % 4 }
    var somaekGlasses: Int { currentSession.somaekGlasses }
    var startTime: Date? { currentSession.startTime }
    var pausedTime: TimeInterval { currentSession.pausedTime }
    var formattedTime: String { currentSession.formattedTime }
    var drinkingSummary: String { currentSession.drinkingSummary }
}
