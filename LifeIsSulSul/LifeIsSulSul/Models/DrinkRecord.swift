import Foundation

struct DrinkRecord: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let sojuBottles: Int
    let sojuShots: Int
    let beerBottles: Int
    let beerGlasses: Int
    let somaekGlasses: Int
    let hourlyPace: [HourlyRecord]
    let totalDuration: TimeInterval
    
    init(date: Date, sojuBottles: Int, sojuShots: Int, beerBottles: Int, beerGlasses: Int, somaekGlasses: Int, hourlyPace: [HourlyRecord], totalDuration: TimeInterval) {
        self.id = UUID()
        self.date = date
        self.sojuBottles = sojuBottles
        self.sojuShots = sojuShots
        self.beerBottles = beerBottles
        self.beerGlasses = beerGlasses
        self.somaekGlasses = somaekGlasses
        self.hourlyPace = hourlyPace
        self.totalDuration = totalDuration
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, sojuBottles, sojuShots, beerBottles, beerGlasses, somaekGlasses, hourlyPace, totalDuration
    }
}