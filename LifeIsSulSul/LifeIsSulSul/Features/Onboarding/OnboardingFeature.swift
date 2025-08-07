import SwiftUI
import ComposableArchitecture

struct OnboardingFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var currentStep = 0
        var hasSeenOnboarding = false
        var buttonScale = 1.0
        var animateEmoji = false
        var sojuLevel: CGFloat = 0
        var beerLevel: CGFloat = 0
    }
    
    @CasePathable
    enum Action {
        case setCurrentStep(Int)
        case completeOnboarding
        case onAppear
        case animateBottles
        case animateButton
        case updateButtonScale(CGFloat)
    }
    
    @Dependency(\.userDefaults) var userDefaults
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setCurrentStep(step):
                state.currentStep = step
                return .none
                
            case .completeOnboarding:
                state.hasSeenOnboarding = true
                userDefaults.set(true, forKey: "hasSeenOnboarding")
                return .none
                
            case .onAppear:
                state.animateEmoji = true
                return .run { send in
                    await send(.animateBottles)
                    await send(.animateButton)
                }
                
            case .animateBottles:
                state.sojuLevel = 0.7
                state.beerLevel = 0.5
                return .none
                
            case .animateButton:
                return .run { send in
                    while true {
                        await send(.updateButtonScale(1.1))
                        try await Task.sleep(for: .seconds(1))
                        await send(.updateButtonScale(1.0))
                        try await Task.sleep(for: .seconds(1))
                    }
                }
                
            case let .updateButtonScale(scale):
                state.buttonScale = scale
                return .none
            }
        }
    }
}
