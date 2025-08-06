import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                TabView(selection: Binding(
                    get: { store.withState(\.currentStep) },
                    set: { store.send(.setCurrentStep($0)) }
                )) {
                    OnboardingStep1(store: store)
                        .tag(0)
                    
                    OnboardingStep2(store: store)
                        .tag(1)
                    
                    OnboardingStep3(store: store)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.withState(\.currentStep))
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

struct OnboardingStep1: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
            VStack(spacing: 40) {
                HStack(spacing: 30) {
                    ImageLiterals.soju
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(store.withState(\.animateEmoji) ? -10 : 10))
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: store.withState(\.animateEmoji))
                    
                    ImageLiterals.beer
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(store.withState(\.animateEmoji) ? 10 : -10))
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: store.withState(\.animateEmoji))
                }
                
                Text("소주잔과 맥주잔을 클릭하며\n오늘 무슨 종류의 술을 몇병 마셨는지\n표시해봐요")
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)
            }
    }
}

struct OnboardingStep2: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
            VStack(spacing: 40) {
                HStack(spacing: 50) {
                    BottleView(fillLevel: store.withState(\.sojuLevel), color: .green.opacity(0.6), bottleType: .soju)
                        .frame(width: 80, height: 200)
                    
                    BottleView(fillLevel: store.withState(\.beerLevel), color: .yellow.opacity(0.7), bottleType: .beer)
                        .frame(width: 80, height: 200)
                }
                
                Text("그렇게 술잔 버튼들 누르면\n소주모양의 병과 맥주모양의 병에\n횟수만큼 액체가 담김")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)
                
                Text("소주는 8잔에 1병\n맥주는 글라스 4잔에 1병")
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
    }
}

struct OnboardingStep3: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
            VStack(spacing: 40) {
                Spacer()
                
                Text("🎉")
                    .font(.system(size: 100))
                    .symbolEffect(.pulse)
                
                Text("자 그럼 '인생이 술술'\n풀리도록 달리러 가봅시다~")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    store.send(.completeOnboarding)
                }) {
                    Text("시작하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(LinearGradient(colors: [.blue, .purple],
                                                   startPoint: .leading,
                                                   endPoint: .trailing))
                        )
                }
                .scaleEffect(store.withState(\.buttonScale))
                
                Spacer()
            }
    }
}

#Preview {
    OnboardingView(store: Store(initialState: OnboardingFeature.State()) {
        OnboardingFeature()
    })
}
