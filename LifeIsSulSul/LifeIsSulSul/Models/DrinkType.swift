import SwiftUI

enum DrinkType: CaseIterable, Equatable, Sendable {
    case soju
    case beer
    case somaek
    
    var glassesPerBottle: Int {
        switch self {
        case .soju: return 8
        case .beer: return 4
        case .somaek: return 0
        }
    }
    
    var name: String {
        switch self {
        case .soju: return "소주"
        case .beer: return "맥주"
        case .somaek: return "소맥"
        }
    }
    
    var color: Color {
        switch self {
        case .soju: return .green
        case .beer: return .orange
        case .somaek: return .purple
        }
    }
    
    var fillColor: Color {
        switch self {
        case .soju: return .green.opacity(0.6)
        case .beer: return .yellow.opacity(0.7)
        case .somaek: return .purple.opacity(0.6)
        }
    }
}