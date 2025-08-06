# TCA 적용 가이드

이 문서는 주량 체크 앱을 TCA(The Composable Architecture)로 전환하기 위한 완성 가이드입니다.

## 🎯 현재 상태

✅ **완료된 작업:**
- 프로젝트 폴더 구조 생성
- Models와 Services 분리
- 모든 TCA Feature 구현 (주석 상태)
- UI 컴포넌트 분리 및 TCA 연결 준비
- 기존 기능을 유지한 임시 ViewModel 구현

## 📦 1단계: TCA 라이브러리 추가

### Xcode에서 Swift Package Manager로 TCA 추가:

1. Xcode에서 프로젝트를 엽니다
2. `File` → `Add Package Dependencies...`
3. URL에 `https://github.com/pointfreeco/swift-composable-architecture` 입력
4. `Add Package` 클릭
5. Target에 `LifeIsSulSul` 선택하고 `Add Package` 클릭

## 🔧 2단계: TCA 코드 활성화

### 2.1 주석 해제 및 import 추가

다음 파일들의 주석 처리된 TCA 코드를 활성화하세요:

```swift
// 각 파일에서 다음 import 주석 해제
import ComposableArchitecture
```

**활성화할 파일들:**
- `AppFeature.swift`
- `Features/Splash/SplashFeature.swift`
- `Features/Onboarding/OnboardingFeature.swift`
- `Features/DrinkTracking/DrinkTrackingFeature.swift`
- `Features/Records/RecordsFeature.swift`
- `Services/DrinkRecordService.swift`
- `LifeIsSulSulApp.swift`

### 2.2 앱 진입점 변경

`LifeIsSulSulApp.swift`에서:

```swift
// 현재 버전을 주석 처리하고
/*
if hasSeenOnboarding {
    DrinkTrackingView()
} else {
    SplashView()
}
*/

// TCA 버전 활성화
AppView(store: Store(initialState: AppFeature.State()) {
    AppFeature()
})
```

### 2.3 View에서 Store 연결

각 View 파일에서 임시 ViewModel을 제거하고 TCA Store를 사용:

**SplashView.swift:**
```swift
struct SplashView: View {
    let store: StoreOf<SplashFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            // 기존 UI 코드
            // onAppear에서: viewStore.send(.onAppear)
        }
    }
}
```

**OnboardingView.swift:**
```swift
struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            // 기존 UI 코드
            // 버튼 액션: viewStore.send(.completeOnboarding)
        }
    }
}
```

**DrinkTrackingView.swift:**
```swift
struct DrinkTrackingView: View {
    let store: StoreOf<DrinkTrackingFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            // 기존 UI 코드
            // 액션 예: viewStore.send(.addDrink(.soju))
        }
    }
}
```

## 🛠 3단계: 의존성 설정

### 3.1 DrinkRecordService 의존성 활성화

`Services/DrinkRecordService.swift`에서 주석 해제:

```swift
extension DependencyValues {
    var drinkRecordService: DrinkRecordServiceProtocol {
        get { self[DrinkRecordServiceKey.self] }
        set { self[DrinkRecordServiceKey.self] = newValue }
    }
}

private enum DrinkRecordServiceKey: DependencyKey {
    static let liveValue: DrinkRecordServiceProtocol = DrinkRecordService()
}
```

### 3.2 UserDefaults 의존성 추가 (필요시)

OnboardingFeature에서 UserDefaults를 사용하므로:

```swift
@Dependency(\.userDefaults) var userDefaults
```

## 🧹 4단계: 정리 작업

### 4.1 임시 파일 제거
- `ContentView.swift` (테스트 완료 후)

### 4.2 임시 ViewModel 제거
각 View 파일에서:
- `OnboardingViewModel` 클래스 제거
- `MainViewModel` 클래스 제거
- `RecordViewModel` 클래스 제거

## 🧪 5단계: 테스트

1. **빌드 테스트:** `Cmd + B`로 빌드 오류 확인
2. **실행 테스트:** 시뮬레이터에서 앱 실행
3. **기능 테스트:** 
   - Splash → Onboarding → Main 화면 전환
   - 음주량 추가/추적 기능
   - 기록 저장/조회 기능

## 🔍 주요 TCA 패턴 설명

### State 관리
```swift
@ObservableState
struct State: Equatable {
    var sojuShots = 0
    var isTracking = false
    // 계산 속성도 가능
    var sojuBottles: Int { sojuShots / 8 }
}
```

### Action 정의
```swift
enum Action {
    case addDrink(DrinkType)
    case startTracking
    case timerTick
}
```

### Reducer 로직
```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .startTracking:
            state.isTracking = true
            return .run { send in
                for await _ in self.clock.timer(interval: .seconds(1)) {
                    await send(.timerTick)
                }
            }
        }
    }
}
```

### View 연결
```swift
WithViewStore(store, observe: { $0 }) { viewStore in
    Button("음주 시작") {
        viewStore.send(.startTracking)
    }
    .disabled(!viewStore.isTracking)
}
```

## 🎉 완료!

모든 단계 완료 후, 앱은 완전한 TCA 아키텍처로 동작하며:
- 단방향 데이터 플로우
- 테스트 가능한 구조
- 명확한 상태 관리
- Side Effect의 명시적 처리

## 🚀 추가 개선 사항

TCA 적용 후 고려할 수 있는 개선 사항들:
1. **Unit Test 추가**: 각 Reducer에 대한 테스트
2. **Navigation 개선**: TCA-Navigation 라이브러리 활용
3. **Persistence**: TCA-Persistence를 통한 상태 저장
4. **Performance**: ViewStore observe 최적화