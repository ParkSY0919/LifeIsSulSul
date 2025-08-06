import SwiftUI
import ComposableArchitecture
import CasePaths

struct AppFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var appState: AppState = .splash
        var splashState = SplashFeature.State()
        var onboardingState = OnboardingFeature.State()
        var drinkTrackingState = DrinkTrackingFeature.State()
        var recordsState = RecordsFeature.State()
    }
    
    @CasePathable
    enum Action {
        case splashAction(SplashFeature.Action)
        case onboardingAction(OnboardingFeature.Action)
        case drinkTrackingAction(DrinkTrackingFeature.Action)
        case recordsAction(RecordsFeature.Action)
        case setAppState(AppState)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splashState, action: \.splashAction) {
            SplashFeature()
        }
        
        Scope(state: \.onboardingState, action: \.onboardingAction) {
            OnboardingFeature()
        }
        
        Scope(state: \.drinkTrackingState, action: \.drinkTrackingAction) {
            DrinkTrackingFeature()
        }
        
        Scope(state: \.recordsState, action: \.recordsAction) {
            RecordsFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .splashAction(.showOnboarding):
                state.appState = .onboarding
                return .none
                
            case .splashAction(.showMain):
                state.appState = .main
                return .none
                
            case .onboardingAction(.completeOnboarding):
                state.appState = .main
                return .none
                
            case let .setAppState(appState):
                state.appState = appState
                return .none
                
            case .splashAction, .onboardingAction, .drinkTrackingAction, .recordsAction:
                return .none
            }
        }
    }
}

enum AppState: Equatable, Sendable {
    case splash
    case onboarding
    case main
}
