import Foundation

//struct CurrentHourlyPace: Sendable, Equatable {
//    let sojuBottles: Int
//    let sojuShots: Int
//    let beerBottles: Int
//    let beerGlasses: Int
//    let somaekGlasses: Int
//    
//    static let empty = CurrentHourlyPace(
//        sojuBottles: 0,
//        sojuShots: 0,
//        beerBottles: 0,
//        beerGlasses: 0,
//        somaekGlasses: 0
//    )
//    
//    init(sojuBottles: Int, sojuShots: Int, beerBottles: Int, beerGlasses: Int, somaekGlasses: Int) {
//        self.sojuBottles = sojuBottles
//        self.sojuShots = sojuShots
//        self.beerBottles = beerBottles
//        self.beerGlasses = beerGlasses
//        self.somaekGlasses = somaekGlasses
//    }
//    
//    init(from record: HourlyRecord) {
//        self.sojuBottles = record.sojuBottles
//        self.sojuShots = record.sojuShots
//        self.beerBottles = record.beerBottles
//        self.beerGlasses = record.beerGlasses
//        self.somaekGlasses = record.somaekGlasses
//    }
//    
//    var hasAnyDrink: Bool {
//        sojuBottles > 0 || sojuShots > 0 || beerBottles > 0 || beerGlasses > 0 || somaekGlasses > 0
//    }
//}
