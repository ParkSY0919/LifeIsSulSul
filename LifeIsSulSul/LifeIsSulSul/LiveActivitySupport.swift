import Foundation
import Combine
import ActivityKit
import ComposableArchitecture
import SwiftUI

// MARK: - Live Activity Intent Handler
@MainActor
class LiveActivityIntentHandler: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    var store: StoreOf<DrinkTrackingFeature>?
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .toggleDrinkingTimer)
            .sink { [weak self] _ in
                self?.handleToggleTimer()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .addSoju)
            .sink { [weak self] _ in
                self?.handleAddSoju()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .addBeer)
            .sink { [weak self] _ in
                self?.handleAddBeer()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .addSomaek)
            .sink { [weak self] _ in
                self?.handleAddSomaek()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .saveRecord)
            .sink { [weak self] _ in
                self?.handleSaveRecord()
            }
            .store(in: &cancellables)
    }
    
    private func handleToggleTimer() {
        guard let store = store else { return }
        
        let isPaused = store.withState(\.isPaused)
        if isPaused {
            store.send(.resumeTracking)
        } else {
            store.send(.stopTracking)
        }
    }
    
    private func handleAddSoju() {
        guard let store = store else { return }
        store.send(.addDrink(.soju))
    }
    
    private func handleAddBeer() {
        guard let store = store else { return }
        store.send(.addDrink(.beer))
    }
    
    private func handleAddSomaek() {
        guard let store = store else { return }
        store.send(.addDrink(.somaek))
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

// MARK: - Notification Names
extension Notification.Name {
    static let toggleDrinkingTimer = Notification.Name("toggleDrinkingTimer")
    static let addSoju = Notification.Name("addSoju")
    static let addBeer = Notification.Name("addBeer")
    static let addSomaek = Notification.Name("addSomaek")
    static let saveRecord = Notification.Name("saveRecord")
}