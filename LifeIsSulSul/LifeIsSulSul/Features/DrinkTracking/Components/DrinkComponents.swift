import SwiftUI

struct DrinkStatusView: View {
    let type: DrinkType
    let bottles: Int
    let units: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Group {
                switch type {
                case .soju:
                    ImageLiterals.soju
                        .resizable()
                        .scaledToFit()
                case .beer:
                    ImageLiterals.beer
                        .resizable()
                        .scaledToFit()
                case .somaek:
                    ImageLiterals.somek
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 25, height: 25)
            
            Text("\(bottles)병 \(units)잔")
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
}

struct DrinkBottleSection: View {
    let type: DrinkType
    let fillLevel: CGFloat
    let onTap: () -> Void
    let isEnabled: Bool
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(type.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(type.color)
            
            BottleView(fillLevel: fillLevel,
                      color: type.fillColor,
                      bottleType: type)
                .frame(width: 80, height: 200)
            
            Button(action: {
                guard isEnabled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed.toggle()
                    onTap()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }) {
                Group {
                    switch type {
                    case .soju:
                        ImageLiterals.soju
                            .resizable()
                            .scaledToFit()
                    case .beer:
                        ImageLiterals.beer
                            .resizable()
                            .scaledToFit()
                    case .somaek:
                        ImageLiterals.somek
                            .resizable()
                            .scaledToFit()
                    }
                }
                .foregroundColor(isEnabled ? type.color : .gray)
                .frame(width: 35, height: 35)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .stroke(isEnabled ? type.color : Color.gray, lineWidth: 3)
                        )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
    }
}

struct BottleView: View {
    let fillLevel: CGFloat
    let color: Color
    let bottleType: DrinkType
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: bottleType == .somaek ? 12 : (bottleType == .soju ? 10 : 15))
                    .stroke(Color.gray, lineWidth: 3)
                
                WaveView(fillLevel: fillLevel,
                        color: color,
                        waveOffset: waveOffset)
                    .mask(
                        RoundedRectangle(cornerRadius: bottleType == .somaek ? 12 : (bottleType == .soju ? 10 : 15))
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
}

struct WaveView: View {
    let fillLevel: CGFloat
    let color: Color
    let waveOffset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let waveHeight: CGFloat = 10
                let yOffset = height * (1 - fillLevel)
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    let y = yOffset + sin(relativeX * .pi * 4 + waveOffset) * waveHeight
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

#Preview {
    VStack {
        DrinkStatusView(type: .soju, bottles: 1, units: 3)
        
        HStack {
            DrinkBottleSection(type: .soju, fillLevel: 0.5, onTap: {}, isEnabled: true)
            DrinkBottleSection(type: .beer, fillLevel: 0.3, onTap: {}, isEnabled: true)
            DrinkBottleSection(type: .somaek, fillLevel: 0.7, onTap: {}, isEnabled: false)
        }
    }
    .padding()
}