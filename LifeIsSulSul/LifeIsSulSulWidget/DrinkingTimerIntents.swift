import Foundation
import Combine
import ActivityKit
import AppIntents
import SwiftUI

// MARK: - Widget Data Manager (Self-contained for Widget Extension)
@MainActor
class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let suiteName = "group.LifeIsSulSul"
    private var userDefaults: UserDefaults
    
    private init() {
        userDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
    
    func addSoju() {
        guard userDefaults.bool(forKey: "SharedData_isTracking") else { return }
        let currentShots = userDefaults.integer(forKey: "SharedData_sojuShots")
        let currentBottles = userDefaults.integer(forKey: "SharedData_sojuBottles")
        
        let newShots = currentShots + 1
        let newBottles = currentBottles + (newShots / 8)
        let remainingShots = newShots % 8
        
        userDefaults.set(newBottles, forKey: "SharedData_sojuBottles")
        userDefaults.set(remainingShots, forKey: "SharedData_sojuShots")
        userDefaults.set(Date(), forKey: "SharedData_lastUpdateTime")
        userDefaults.synchronize()
        
        print("WidgetDataManager: Added soju - \(newBottles)병 \(remainingShots)잔")
    }
    
    func addBeer() {
        guard userDefaults.bool(forKey: "SharedData_isTracking") else { return }
        let currentGlasses = userDefaults.integer(forKey: "SharedData_beerGlasses")
        let currentBottles = userDefaults.integer(forKey: "SharedData_beerBottles")
        
        let newGlasses = currentGlasses + 1
        let newBottles = currentBottles + (newGlasses / 4)
        let remainingGlasses = newGlasses % 4
        
        userDefaults.set(newBottles, forKey: "SharedData_beerBottles")
        userDefaults.set(remainingGlasses, forKey: "SharedData_beerGlasses")
        userDefaults.set(Date(), forKey: "SharedData_lastUpdateTime")
        userDefaults.synchronize()
        
        print("WidgetDataManager: Added beer - \(newBottles)병 \(remainingGlasses)잔")
    }
    
    func addSomaek() {
        guard userDefaults.bool(forKey: "SharedData_isTracking") else { return }
        let currentGlasses = userDefaults.integer(forKey: "SharedData_somaekGlasses")
        let newGlasses = currentGlasses + 1
        
        userDefaults.set(newGlasses, forKey: "SharedData_somaekGlasses")
        userDefaults.set(Date(), forKey: "SharedData_lastUpdateTime")
        userDefaults.synchronize()
        
        print("WidgetDataManager: Added somaek - \(newGlasses)잔")
    }
    
    func toggleTimer() {
        let isTracking = userDefaults.bool(forKey: "SharedData_isTracking")
        let isPaused = userDefaults.bool(forKey: "SharedData_isPaused")
        
        if isTracking {
            userDefaults.set(false, forKey: "SharedData_isTracking")
            userDefaults.set(true, forKey: "SharedData_isPaused")
        } else if isPaused {
            userDefaults.set(true, forKey: "SharedData_isTracking")
            userDefaults.set(false, forKey: "SharedData_isPaused")
        }
        
        userDefaults.set(Date(), forKey: "SharedData_lastUpdateTime")
        userDefaults.synchronize()
        
        print("WidgetDataManager: Toggled timer - isTracking: \(!isTracking), isPaused: \(!isPaused)")
    }
}

// MARK: - Toggle Timer Intent (Pause/Resume)
struct DrinkingTimerToggleIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "음주 타이머 일시정지/재시작"
    static let description = IntentDescription("음주 타이머를 일시정지하거나 재시작합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            print("DrinkingTimerToggleIntent: Toggling timer state")
            WidgetDataManager.shared.toggleTimer()
        }
        return .result()
    }
}


// MARK: - Add Soju Intent
struct AddSojuIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "소주 추가"
    static let description: IntentDescription = IntentDescription("소주 1잔을 추가합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            print("AddSojuIntent: Adding soju shot")
            WidgetDataManager.shared.addSoju()
        }
        return .result()
    }
}

// MARK: - Add Beer Intent
struct AddBeerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "맥주 추가"
    static let description: IntentDescription = IntentDescription("맥주 1잔을 추가합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            print("AddBeerIntent: Adding beer glass")
            WidgetDataManager.shared.addBeer()
        }
        return .result()
    }
}

// MARK: - Add Somaek Intent
struct AddSomaekIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "소맥 추가"
    static let description: IntentDescription = IntentDescription("소맥 1잔을 추가합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            print("AddSomaekIntent: Adding somaek glass")
            WidgetDataManager.shared.addSomaek()
        }
        return .result()
    }
}

// MARK: - Save Record Intent
struct SaveRecordIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "기록 저장"
    static let description: IntentDescription = IntentDescription("현재 음주 기록을 저장합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .saveRecord, object: nil)
        return .result()
    }
}

// MARK: - Open App Intent
struct OpenAppIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "앱 열기"
    static let description: IntentDescription = IntentDescription("LifeIsSulSul 앱을 엽니다")
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Notification Names (deprecated - now using SharedDataManager)
extension Notification.Name {
    static let saveRecord = Notification.Name("saveRecord")
}


// MARK: - Live Activity Permission Manager
class LiveActivityPermissionManager: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var hasRequestedPermission: Bool = false
    
    init() {
        checkPermissionStatus()
    }
    
    func checkPermissionStatus() {
        let authInfo = ActivityAuthorizationInfo()
        self.isEnabled = authInfo.areActivitiesEnabled
    }
    
    func requestPermission() {
        let authInfo = ActivityAuthorizationInfo()
        self.isEnabled = authInfo.areActivitiesEnabled
        self.hasRequestedPermission = true
    }
}
