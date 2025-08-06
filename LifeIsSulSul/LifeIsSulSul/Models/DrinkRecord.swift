import Foundation

struct DrinkRecord: Codable, Equatable, Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let sojuBottles: Int
    let sojuShots: Int
    let beerBottles: Int
    let beerGlasses: Int
    let somaekGlasses: Int
    let hourlyPace: [HourlyRecord]
    let totalDuration: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case date, sojuBottles, sojuShots, beerBottles, beerGlasses, somaekGlasses, hourlyPace, totalDuration
    }
}