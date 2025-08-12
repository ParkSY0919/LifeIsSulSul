import Foundation
import Combine
import ActivityKit
import ComposableArchitecture
import SwiftUI

// MARK: - Live Activity Intent Handler (간소화됨)
@MainActor
class LiveActivityIntentHandler: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    var store: StoreOf<DrinkTrackingFeature>?
    
    init() {
        setupNotificationObservers()
        print("LiveActivityIntentHandler: Initialized (메모리 기반 구조로 대부분의 동기화 로직 제거됨)")
    }
    
    private func setupNotificationObservers() {
        // 저장 요청만 처리 (나머지는 SharedDataManager.currentSession이 자동 처리)
        NotificationCenter.default.publisher(for: .saveRecord)
            .sink { [weak self] _ in
                self?.handleSaveRecord()
            }
            .store(in: &cancellables)
    }
    
    private func handleSaveRecord() {
        guard let store = store else { return }
        store.send(.saveRecord)
    }
    
    func setStore(_ store: StoreOf<DrinkTrackingFeature>) {
        self.store = store
    }
}

// MARK: - Live Activity Permission Manager
@MainActor
class LiveActivityPermissionManager: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var hasRequestedPermission: Bool = false
    @Published var showSettingsAlert: Bool = false
    
    init() {
        checkPermissionStatus()
        startMonitoringPermissionStatus()
    }
    
    func checkPermissionStatus() {
        let authInfo = ActivityAuthorizationInfo()
        self.isEnabled = authInfo.areActivitiesEnabled
    }
    
    private func startMonitoringPermissionStatus() {
        // 주기적으로 권한 상태 확인
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            let authInfo = ActivityAuthorizationInfo()
            let newStatus = authInfo.areActivitiesEnabled
            Task { @MainActor in
                if self?.isEnabled != newStatus {
                    self?.isEnabled = newStatus
                }
            }
        }
    }
    
    func requestPermissionOrOpenSettings() {
        let authInfo = ActivityAuthorizationInfo()
        
        if authInfo.areActivitiesEnabled {
            self.isEnabled = true
        } else if hasRequestedPermission {
            // 이미 한 번 요청했다면 설정 앱으로 안내
            self.showSettingsAlert = true
        } else {
            // 처음 요청하는 경우 - 실제로는 Live Activity 시작 시 자동으로 물어봄
            self.hasRequestedPermission = true
            self.showSettingsAlert = true
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
}

// MARK: - Notification Names (deprecated - most actions now use SharedDataManager)
extension Notification.Name {
    static let saveRecord = Notification.Name("saveRecord")
}