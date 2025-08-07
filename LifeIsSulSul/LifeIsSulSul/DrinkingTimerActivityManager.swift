import Foundation
import ActivityKit

@MainActor
class DrinkingTimerActivityManager: ObservableObject {
    static let shared = DrinkingTimerActivityManager()
    
    @Published var currentActivity: Activity<DrinkingTimerActivity>?
    
    private init() {
        cleanupExistingActivities()
    }
    
    private func cleanupExistingActivities() {
        Task {
            for activity in Activity<DrinkingTimerActivity>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    
    func startActivity(sessionStartTime: Date, userName: String? = nil) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // 기존 Activity가 있다면 종료
        if let existingActivity = currentActivity {
            Task {
                await existingActivity.end(nil, dismissalPolicy: .immediate)
                await MainActor.run {
                    self.currentActivity = nil
                }
            }
        }
        
        let attributes = DrinkingTimerActivity(
            sessionStartTime: sessionStartTime,
            userName: userName
        )
        
        let contentState = DrinkingTimerContentState(
            isActive: true,
            isPaused: false,
            elapsedTime: 0,
            sojuBottles: 0,
            sojuShots: 0,
            beerBottles: 0,
            beerGlasses: 0,
            somaekGlasses: 0,
            currentHourlyPace: "보통",
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(state: contentState, staleDate: nil)
        
        do {
            let activity = try Activity<DrinkingTimerActivity>.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            self.currentActivity = activity
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateActivity(
        isActive: Bool,
        isPaused: Bool,
        elapsedTime: TimeInterval,
        sojuBottles: Int,
        sojuShots: Int,
        beerBottles: Int,
        beerGlasses: Int,
        somaekGlasses: Int,
        currentHourlyPace: String = "보통"
    ) async {
        guard let activity = currentActivity else { return }
        
        let contentState = DrinkingTimerContentState(
            isActive: isActive,
            isPaused: isPaused,
            elapsedTime: elapsedTime,
            sojuBottles: sojuBottles,
            sojuShots: sojuShots,
            beerBottles: beerBottles,
            beerGlasses: beerGlasses,
            somaekGlasses: somaekGlasses,
            currentHourlyPace: currentHourlyPace,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(state: contentState, staleDate: nil)
        
        do {
            await activity.update(activityContent)
        } catch {
            print("Failed to update Live Activity: \(error)")
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            await MainActor.run {
                self.currentActivity = nil
            }
        }
    }
}