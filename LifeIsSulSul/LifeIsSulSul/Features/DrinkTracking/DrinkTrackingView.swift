import SwiftUI
import ComposableArchitecture

struct DrinkTrackingView: View {
    let store: StoreOf<DrinkTrackingFeature>
    
    var body: some View {
        NavigationStack {
            MainView(store: store)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            store.send(.showRecords)
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                        }
                    }
                }
                .navigationTitle("인생이 술술")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: Binding(
                    get: { store.withState(\.showRecords) },
                    set: { _ in store.send(.hideRecords) }
                )) {
                    RecordView(store: Store(initialState: RecordsFeature.State()) {
                        RecordsFeature()
                    })
                }
        }
    }
}

struct MainView: View {
    let store: StoreOf<DrinkTrackingFeature>
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                // 상단 음주량 표시
                DrinkStatusSection(store: store)
                
                // 타이머 표시
                if store.withState(\.isTracking) || store.withState(\.isPaused) {
                    Text(store.withState(\.formattedTime))
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                }
                
                // 시간당 페이스 표시
                HourlyPaceSection(store: store)
                
                Spacer()
                
                // 중앙 병 표시
                DrinkBottlesSection(store: store)
                
                Spacer()
                
                // 하단 버튼
                ControlButtonsSection(store: store)
            }
            .padding(.vertical)
        }
    }
}

struct DrinkStatusSection: View {
    let store: StoreOf<DrinkTrackingFeature>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                DrinkStatusView(type: .soju,
                              bottles: store.withState(\.sojuBottles),
                              units: store.withState(\.sojuShots) % 8)
                
                DrinkStatusView(type: .beer,
                              bottles: store.withState(\.beerBottles),
                              units: store.withState(\.beerGlasses) % 4)
                
                HStack(spacing: 8) {
                    ImageLiterals.somek
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    
                    Text("\(store.withState(\.somaekGlasses))잔")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                )
            }
            
            Spacer()
            
            if store.withState(\.isTracking) {
                Button(action: {
                    store.send(.stopTracking)
                }) {
                    Text("STOP")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.red))
                }
            }
        }
        .padding(.horizontal)
    }
}

struct HourlyPaceSection: View {
    let store: StoreOf<DrinkTrackingFeature>
    
    var body: some View {
        if store.withState(\.currentHourlyPace.hasAnyDrink) {
            VStack(spacing: 4) {
                Text("현재 시간 페이스")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    let pace = store.withState(\.currentHourlyPace)
                    if pace.sojuBottles > 0 || pace.sojuShots > 0 {
                        HStack(spacing: 4) {
                            ImageLiterals.soju
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(pace.sojuBottles)병 \(pace.sojuShots)잔/시간")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if pace.beerBottles > 0 || pace.beerGlasses > 0 {
                        HStack(spacing: 4) {
                            ImageLiterals.beer
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(pace.beerBottles)병 \(pace.beerGlasses)잔/시간")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if pace.somaekGlasses > 0 {
                        HStack(spacing: 4) {
                            ImageLiterals.somek
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(pace.somaekGlasses)잔/시간")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.yellow.opacity(0.2))
                )
            }
            .padding(.top, 5)
        }
    }
}

struct DrinkBottlesSection: View {
    let store: StoreOf<DrinkTrackingFeature>
    
    var body: some View {
        HStack(spacing: 30) {
            DrinkBottleSection(type: .soju,
                             fillLevel: store.withState(\.sojuFillLevel),
                             onTap: { 
                                 store.send(.addDrink(.soju))
                             },
                             isEnabled: store.withState(\.isTracking))
            
            DrinkBottleSection(type: .somaek,
                             fillLevel: store.withState(\.somaekFillLevel),
                             onTap: { 
                                 store.send(.addDrink(.somaek))
                             },
                             isEnabled: store.withState(\.isTracking))
            
            DrinkBottleSection(type: .beer,
                             fillLevel: store.withState(\.beerFillLevel),
                             onTap: { 
                                 store.send(.addDrink(.beer))
                             },
                             isEnabled: store.withState(\.isTracking))
        }
    }
}

struct ControlButtonsSection: View {
    let store: StoreOf<DrinkTrackingFeature>
    
    var body: some View {
        if !store.withState(\.isTracking) {
            if store.withState(\.isPaused) {
                HStack(spacing: 20) {
                    Button(action: {
                        store.send(.resumeTracking)
                    }) {
                        Text("재개")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.green)
                            )
                    }
                    
                    Button(action: {
                        store.send(.saveRecord)
                    }) {
                        Text("저장")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.blue)
                            )
                    }
                }
            } else {
                Button(action: {
                    store.send(.startTracking)
                }) {
                    Text("음주 시작")
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
                .shadow(radius: 5)
            }
        }
    }
}

#Preview {
    DrinkTrackingView(store: Store(initialState: DrinkTrackingFeature.State()) {
        DrinkTrackingFeature()
    })
}