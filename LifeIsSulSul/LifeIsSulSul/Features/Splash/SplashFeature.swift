import SwiftUI
import ComposableArchitecture

struct SplashFeature: Reducer {
    struct State: Equatable {
        var showOnboarding = false
    }
    
    enum Action {
        case onAppear
        case showOnboarding
        case showMain
        case timerCompleted
    }
    
    @Dependency(\.userDefaults) var userDefaults
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.timerCompleted)
                }
                
            case .timerCompleted:
                let hasSeenOnboarding = userDefaults.bool(forKey: "hasSeenOnboarding")
                if hasSeenOnboarding {
                    return .send(.showMain)
                } else {
                    state.showOnboarding = true
                    return .send(.showOnboarding)
                }
                
            case .showOnboarding:
                return .none
                
            case .showMain:
                return .none
            }
        }
    }
}
