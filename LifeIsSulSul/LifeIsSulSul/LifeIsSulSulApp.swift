//
//  LifeIsSulSulApp.swift
//  LifeIsSulSul
//
//  Created by 박신영 on 8/5/25.
//

import SwiftUI
import ComposableArchitecture
import ActivityKit
import WidgetKit


@main
struct LifeIsSulSulApp: App {
    
    init() {
        // Widget 등록
        if #available(iOS 16.1, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State()) {
                AppFeature()
            })
        }
    }
}

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var intentHandler = LiveActivityIntentHandler()
    @StateObject private var permissionManager = LiveActivityPermissionManager()
    
    var body: some View {
        Group {
            switch store.appState {
            case .splash:
                SplashView(store: store.scope(state: \.splashState, action: \.splashAction))
                
            case .onboarding:
                OnboardingView(store: store.scope(state: \.onboardingState, action: \.onboardingAction))
                
            case .main:
                DrinkTrackingView(store: store.scope(state: \.drinkTrackingState, action: \.drinkTrackingAction))
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.drinkTrackingAction(.scenePhaseChanged(newPhase)))
        }
        .onAppear {
            if #available(iOS 16.1, *) {
                intentHandler.setStore(store.scope(state: \.drinkTrackingState, action: \.drinkTrackingAction))
                permissionManager.checkPermissionStatus()
            }
        }
        .alert("Live Activities 설정", isPresented: $permissionManager.showSettingsAlert) {
            Button("설정으로 이동") {
                permissionManager.openSettings()
            }
            Button("나중에", role: .cancel) { }
        } message: {
            Text("잠금화면에서 음주 타이머를 보려면 Live Activities를 활성화해주세요.\n\n설정 > 알림 > LifeIsSulSul > Live Activities")
        }
    }
}
