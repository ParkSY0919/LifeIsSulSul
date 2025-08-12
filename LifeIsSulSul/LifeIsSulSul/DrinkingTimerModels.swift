import Foundation
import ActivityKit
import SwiftUI

// MARK: - Supporting Data Models

struct HourlyRecord: Codable, Equatable, Sendable {
    let hour: Int
    let sojuBottles: Int
    let sojuShots: Int
    let beerBottles: Int
    let beerGlasses: Int
    let somaekGlasses: Int
}

struct CurrentHourlyPace: Sendable, Equatable {
    let sojuBottles: Int
    let sojuShots: Int
    let beerBottles: Int
    let beerGlasses: Int
    let somaekGlasses: Int
    
    static let empty = CurrentHourlyPace(
        sojuBottles: 0,
        sojuShots: 0,
        beerBottles: 0,
        beerGlasses: 0,
        somaekGlasses: 0
    )
    
    init(sojuBottles: Int, sojuShots: Int, beerBottles: Int, beerGlasses: Int, somaekGlasses: Int) {
        self.sojuBottles = sojuBottles
        self.sojuShots = sojuShots
        self.beerBottles = beerBottles
        self.beerGlasses = beerGlasses
        self.somaekGlasses = somaekGlasses
    }
    
    init(from record: HourlyRecord) {
        self.sojuBottles = record.sojuBottles
        self.sojuShots = record.sojuShots
        self.beerBottles = record.beerBottles
        self.beerGlasses = record.beerGlasses
        self.somaekGlasses = record.somaekGlasses
    }
    
    var hasAnyDrink: Bool {
        sojuBottles > 0 || sojuShots > 0 || beerBottles > 0 || beerGlasses > 0 || somaekGlasses > 0
    }
}

// MARK: - Memory-based Drinking Session
@MainActor
public class DrinkingSession: ObservableObject {
    // 음주량 데이터
    @Published var sojuShots = 0
    @Published var beerGlasses = 0
    @Published var somaekGlasses = 0
    
    // 타이머 상태
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var startTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var pausedTime: TimeInterval = 0
    
    // 시간당 페이스 추적
    var hourlyPace: [HourlyRecord] = []
    var currentHourlyPace: CurrentHourlyPace = .empty
    
    // 기타
    var lastSaveTime: Date?
    var backgroundEnterTime: Date?
    
    // MARK: - Computed Properties
    
    var sojuBottles: Int { sojuShots / 8 }
    var beerBottles: Int { beerGlasses / 4 }
    
    var sojuFillLevel: CGFloat { CGFloat(sojuShots % 8) / 8.0 }
    var beerFillLevel: CGFloat { CGFloat(beerGlasses % 4) / 4.0 }
    var somaekFillLevel: CGFloat { CGFloat(somaekGlasses % 10) / 10.0 }
    
    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d시간 %02d분", hours, minutes)
        } else {
            return String(format: "%02d분 %02d초", minutes, seconds)
        }
    }
    
    var drinkingSummary: String {
        var drinks: [String] = []
        
        if sojuBottles > 0 || sojuShots > 0 {
            let remainingShots = sojuShots % 8
            if sojuBottles == 0 {
                drinks.append("소주 \(remainingShots)잔")
            } else if remainingShots == 0 {
                drinks.append("소주 \(sojuBottles)병")
            } else {
                drinks.append("소주 \(sojuBottles)병 \(remainingShots)잔")
            }
        }
        
        if beerBottles > 0 || beerGlasses > 0 {
            let remainingGlasses = beerGlasses % 4
            if beerBottles == 0 {
                drinks.append("맥주 \(remainingGlasses)잔")
            } else if remainingGlasses == 0 {
                drinks.append("맥주 \(beerBottles)병")
            } else {
                drinks.append("맥주 \(beerBottles)병 \(remainingGlasses)잔")
            }
        }
        
        if somaekGlasses > 0 {
            drinks.append("소맥 \(somaekGlasses)잔")
        }
        
        return drinks.isEmpty ? "음주 기록 없음" : drinks.joined(separator: ", ")
    }
    
    // MARK: - Actions
    
    func addSoju() {
        guard isTracking else { return }
        sojuShots += 1
        print("DrinkingSession: Added soju shot, total: \(sojuBottles)병 \(sojuShots % 8)잔")
    }
    
    func addBeer() {
        guard isTracking else { return }
        beerGlasses += 1
        print("DrinkingSession: Added beer glass, total: \(beerBottles)병 \(beerGlasses % 4)잔")
    }
    
    func addSomaek() {
        guard isTracking else { return }
        somaekGlasses += 1
        print("DrinkingSession: Added somaek glass, total: \(somaekGlasses)잔")
    }
    
    func startTracking() {
        isTracking = true
        isPaused = false
        startTime = Date()
        elapsedTime = 0
        pausedTime = 0
        hourlyPace = []
        currentHourlyPace = .empty
        lastSaveTime = Date()
        print("DrinkingSession: Started tracking")
    }
    
    func stopTracking() {
        isTracking = false
        isPaused = true
        
        // 정확한 시간 계산
        if let startTime = startTime {
            let currentTime = Date()
            elapsedTime = currentTime.timeIntervalSince(startTime) - pausedTime
        }
        print("DrinkingSession: Stopped tracking, elapsed: \(formattedTime)")
    }
    
    func resumeTracking() {
        guard isPaused else { return }
        
        let pauseStartTime = backgroundEnterTime ?? Date()
        let pauseDuration = Date().timeIntervalSince(pauseStartTime)
        pausedTime += pauseDuration
        
        isTracking = true
        isPaused = false
        backgroundEnterTime = nil
        print("DrinkingSession: Resumed tracking")
    }
    
    func updateElapsedTime() {
        guard isTracking, let startTime = startTime else { return }
        let currentTime = Date()
        elapsedTime = currentTime.timeIntervalSince(startTime) - pausedTime
    }
    
    func reset() {
        sojuShots = 0
        beerGlasses = 0
        somaekGlasses = 0
        isTracking = false
        isPaused = false
        startTime = nil
        elapsedTime = 0
        pausedTime = 0
        hourlyPace = []
        currentHourlyPace = .empty
        lastSaveTime = nil
        backgroundEnterTime = nil
        print("DrinkingSession: Reset completed")
    }
    
    // MARK: - LiveActivity State Conversion
    
    func toContentState() -> DrinkingTimerContentState {
        return DrinkingTimerContentState(
            isActive: isTracking,
            isPaused: isPaused,
            elapsedTime: elapsedTime,
            sojuBottles: sojuBottles,
            sojuShots: sojuShots % 8,
            beerBottles: beerBottles,
            beerGlasses: beerGlasses % 4,
            somaekGlasses: somaekGlasses,
            currentHourlyPace: "보통",
            lastUpdateTime: Date()
        )
    }
}

struct DrinkingTimerActivity: ActivityAttributes {
    public typealias ContentState = DrinkingTimerContentState
    
    var sessionStartTime: Date
    var userName: String?
}

struct DrinkingTimerContentState: Sendable, Codable, Hashable {
    var isActive: Bool
    var isPaused: Bool
    var elapsedTime: TimeInterval
    var sojuBottles: Int
    var sojuShots: Int
    var beerBottles: Int
    var beerGlasses: Int
    var somaekGlasses: Int
    var currentHourlyPace: String
    var lastUpdateTime: Date
    
    var totalSojuCount: String {
        if sojuBottles == 0 && sojuShots == 0 {
            return ""
        } else if sojuBottles == 0 {
            return "소주 \(sojuShots)잔"
        } else if sojuShots == 0 {
            return "소주 \(sojuBottles)병"
        } else {
            return "소주 \(sojuBottles)병 \(sojuShots)잔"
        }
    }
    
    var totalBeerCount: String {
        if beerBottles == 0 && beerGlasses == 0 {
            return ""
        } else if beerBottles == 0 {
            return "맥주 \(beerGlasses)잔"
        } else if beerGlasses == 0 {
            return "맥주 \(beerBottles)병"
        } else {
            return "맥주 \(beerBottles)병 \(beerGlasses)잔"
        }
    }
    
    var somaekCount: String {
        somaekGlasses > 0 ? "소맥 \(somaekGlasses)잔" : ""
    }
    
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
    
    var statusIcon: String {
        if !isActive {
            return "⏹️"
        } else if isPaused {
            return "⏸️"
        } else {
            return "🍻"
        }
    }
    
    var drinkingSummary: String {
        let drinks = [totalSojuCount, totalBeerCount, somaekCount].filter { !$0.isEmpty }
        return drinks.isEmpty ? "음주 기록 없음" : drinks.joined(separator: ", ")
    }
}
