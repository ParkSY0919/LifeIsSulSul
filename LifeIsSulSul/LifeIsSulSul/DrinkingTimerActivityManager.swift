import Foundation
import ActivityKit

@MainActor
class DrinkingTimerActivityManager: ObservableObject {
    static let shared = DrinkingTimerActivityManager()
    
    @Published var currentActivity: Activity<DrinkingTimerActivity>?
    
    private init() {
        cleanupExistingActivities()
        setupDataObserver()
    }
    
    private func setupDataObserver() {
        // SharedDataManager의 currentSession 변경 시 LiveActivity 업데이트
        SharedDataManager.shared.onSessionChanged = { [weak self] session in
            Task { @MainActor in
                print("DrinkingTimerActivityManager: Session changed, updating LiveActivity")
                await self?.updateActivityFromSession(session)
            }
        }
        
        print("DrinkingTimerActivityManager: Session observer setup completed")
    }
    
    private func updateActivityFromSession(_ session: DrinkingSession) async {
        guard currentActivity != nil else {
            print("DrinkingTimerActivityManager: No active LiveActivity to update")
            return
        }
        
        print("DrinkingTimerActivityManager: Updating LiveActivity with session - Soju: \(session.sojuBottles)병 \(session.sojuShots % 8)잔, Beer: \(session.beerBottles)병 \(session.beerGlasses % 4)잔, Somaek: \(session.somaekGlasses)잔")
        
        await updateActivity(
            isActive: session.isTracking,
            isPaused: session.isPaused,
            elapsedTime: session.elapsedTime,
            sojuBottles: session.sojuBottles,
            sojuShots: session.sojuShots % 8,
            beerBottles: session.beerBottles,
            beerGlasses: session.beerGlasses % 4,
            somaekGlasses: session.somaekGlasses
        )
    }
    
    private func cleanupExistingActivities() {
        Task {
            for activity in Activity<DrinkingTimerActivity>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    
    func startActivity(sessionStartTime: Date, userName: String? = nil) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        if let existingActivity = currentActivity {
            await existingActivity.end(nil, dismissalPolicy: .immediate)
            await MainActor.run {
                self.currentActivity = nil
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
        guard let activity = currentActivity else { 
            print("DrinkingTimerActivityManager: updateActivity called but no current activity")
            return 
        }
        
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
            print("DrinkingTimerActivityManager: LiveActivity updated successfully")
        } catch {
            print("DrinkingTimerActivityManager: Failed to update LiveActivity: \(error)")
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
