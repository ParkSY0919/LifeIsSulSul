import Foundation
import Combine
import ActivityKit
import AppIntents
import SwiftUI

// MARK: - Toggle Timer Intent (Pause/Resume)
struct DrinkingTimerToggleIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "음주 타이머 일시정지/재시작"
    static let description = IntentDescription("음주 타이머를 일시정지하거나 재시작합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .toggleDrinkingTimer, object: nil)
        return .result()
    }
}


// MARK: - Add Soju Intent
struct AddSojuIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "소주 추가"
    static let description: IntentDescription = IntentDescription("소주 1잔을 추가합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .addSoju, object: nil)
        return .result()
    }
}

// MARK: - Add Beer Intent
struct AddBeerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "맥주 추가"
    static let description: IntentDescription = IntentDescription("맥주 1잔을 추가합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .addBeer, object: nil)
        return .result()
    }
}

// MARK: - Add Somaek Intent
struct AddSomaekIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "소맥 추가"
    static let description: IntentDescription = IntentDescription("소맥 1잔을 추가합니다")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .addSomaek, object: nil)
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

// MARK: - Notification Names
extension Notification.Name {
    static let toggleDrinkingTimer = Notification.Name("toggleDrinkingTimer")
    static let addSoju = Notification.Name("addSoju")
    static let addBeer = Notification.Name("addBeer")
    static let addSomaek = Notification.Name("addSomaek")
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
//        Task {
            let authInfo = ActivityAuthorizationInfo()
//            await MainActor.run {
                self.isEnabled = authInfo.areActivitiesEnabled
                self.hasRequestedPermission = true
//            }
//        }
    }
}
