import SwiftUI
import ComposableArchitecture

struct SplashView: View {
    @Bindable var store: StoreOf<SplashFeature>
    
    var body: some View {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 140, height: 140)
                        .overlay(
                            ImageLiterals.logo
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        )
                        .scaleEffect(store.showOnboarding ? 1.2 : 1.0)
                        .shadow(radius: 10)
                    
                    Text("인생이 술술")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
                .scaleEffect(store.showOnboarding ? 0 : 1)
                .opacity(store.showOnboarding ? 0 : 1)
            }
            .onAppear {
                store.send(.onAppear)
            }
    }
}

#Preview {
    SplashView(store: Store(initialState: SplashFeature.State()) {
        SplashFeature()
    })
}
