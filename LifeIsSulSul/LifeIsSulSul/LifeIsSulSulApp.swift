//
//  LifeIsSulSulApp.swift
//  LifeIsSulSul
//
//  Created by 박신영 on 8/5/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct LifeIsSulSulApp: App {
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
    
    var body: some View {
        switch store.appState {
        case .splash:
            SplashView(store: store.scope(state: \.splashState, action: \.splashAction))
            
        case .onboarding:
            OnboardingView(store: store.scope(state: \.onboardingState, action: \.onboardingAction))
            
        case .main:
            DrinkTrackingView(store: store.scope(state: \.drinkTrackingState, action: \.drinkTrackingAction))
        }
    }
}
