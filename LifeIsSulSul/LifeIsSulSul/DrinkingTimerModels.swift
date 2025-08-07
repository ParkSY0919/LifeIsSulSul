import Foundation
import ActivityKit

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