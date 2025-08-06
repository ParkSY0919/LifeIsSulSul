import SwiftUI
import ComposableArchitecture

struct RecordView: View {
    let store: StoreOf<RecordsFeature>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                if store.withState(\.isLoading) {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if store.withState(\.records.isEmpty) {
                    VStack {
                        Image(systemName: "wineglass")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("아직 기록이 없습니다")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Menu {
                                ForEach(SortOrder.allCases, id: \.self) { order in
                                    Button(action: {
                                        store.send(.setSortOrder(order))
                                    }) {
                                        HStack {
                                            Text(order.rawValue)
                                            if store.withState(\.sortOrder) == order {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(store.withState(\.sortOrder.rawValue))
                                        .font(.caption)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                let sortedRecords = store.withState(\.sortedRecords)
                                ForEach(sortedRecords.indices, id: \.self) { index in
                                    RecordCard(record: sortedRecords[index])
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            store.send(.refresh)
                        }
                    }
                }
            }
            .navigationTitle("음주 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                store.send(.loadRecords)
            }
        }
    }
}

struct RecordCard: View {
    let record: DrinkRecord
    
    private var formattedDuration: String {
        let hours = Int(record.totalDuration) / 3600
        let minutes = (Int(record.totalDuration) % 3600) / 60
        let seconds = Int(record.totalDuration) % 60
        return String(format: "%d시간 %02d분 %02d초", hours, minutes, seconds)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd EEEE"
        return formatter.string(from: record.date)
    }
    
    private var averagePace: (soju: (bottles: Int, shots: Int), beer: (bottles: Int, glasses: Int), somaek: Int) {
        guard !record.hourlyPace.isEmpty else { return (soju: (0, 0), beer: (0, 0), somaek: 0) }
        
        let totalSojuShots = record.hourlyPace.reduce(0) { $0 + $1.sojuBottles * 8 + $1.sojuShots }
        let totalBeerGlasses = record.hourlyPace.reduce(0) { $0 + $1.beerBottles * 4 + $1.beerGlasses }
        let totalSomaekGlasses = record.hourlyPace.reduce(0) { $0 + $1.somaekGlasses }
        let hours = record.hourlyPace.count
        
        let avgSojuShots = totalSojuShots / hours
        let avgBeerGlasses = totalBeerGlasses / hours
        let avgSomaekGlasses = totalSomaekGlasses / hours
        
        return (
            soju: (avgSojuShots / 8, avgSojuShots % 8),
            beer: (avgBeerGlasses / 4, avgBeerGlasses % 4),
            somaek: avgSomaekGlasses
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RecordCardHeader(
                formattedDate: formattedDate,
                formattedDuration: formattedDuration
            )
            
            RecordCardDrinkCounts(record: record)
            
            if !record.hourlyPace.isEmpty {
                Divider()
                RecordCardHourlyPace(
                    averagePace: averagePace,
                    hourlyPace: record.hourlyPace
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 2)
        )
    }
}

struct RecordCardHeader: View {
    let formattedDate: String
    let formattedDuration: String
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.headline)
            
            Spacer()
            
            Text(formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                )
        }
    }
}

struct RecordCardDrinkCounts: View {
    let record: DrinkRecord
    
    var body: some View {
        HStack {
            Label("\(record.sojuBottles)병 \(record.sojuShots)잔", systemImage: "wineglass")
                .foregroundColor(.green)
            
            Spacer()
            
            Label("\(record.beerBottles)병 \(record.beerGlasses)잔", systemImage: "mug")
                .foregroundColor(.orange)
            
            Spacer()
            
            Label("\(record.somaekGlasses)잔", systemImage: "drop.circle")
                .foregroundColor(.purple)
        }
    }
}

struct RecordCardHourlyPace: View {
    let averagePace: (soju: (bottles: Int, shots: Int), beer: (bottles: Int, glasses: Int), somaek: Int)
    let hourlyPace: [HourlyRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("평균 시간당 페이스")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            AveragePaceRow(averagePace: averagePace)
            
            DisclosureGroup("시간별 상세 기록") {
                HourlyDetailView(hourlyPace: hourlyPace)
            }
            .font(.caption)
            .tint(.secondary)
        }
    }
}

struct AveragePaceRow: View {
    let averagePace: (soju: (bottles: Int, shots: Int), beer: (bottles: Int, glasses: Int), somaek: Int)
    
    var body: some View {
        HStack {
            if averagePace.soju.bottles > 0 || averagePace.soju.shots > 0 {
                HStack(spacing: 4) {
                    ImageLiterals.soju
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(averagePace.soju.bottles)병 \(averagePace.soju.shots)잔/시간")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if averagePace.beer.bottles > 0 || averagePace.beer.glasses > 0 {
                HStack(spacing: 4) {
                    ImageLiterals.beer
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(averagePace.beer.bottles)병 \(averagePace.beer.glasses)잔/시간")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if averagePace.somaek > 0 {
                HStack(spacing: 4) {
                    ImageLiterals.somek
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(averagePace.somaek)잔/시간")
                        .font(.caption)
                }
            }
        }
    }
}

struct HourlyDetailView: View {
    let hourlyPace: [HourlyRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(hourlyPace.indices, id: \.self) { index in
                HourlyDetailRow(
                    hourIndex: index,
                    hourlyRecord: hourlyPace[index]
                )
            }
        }
        .padding(.top, 4)
    }
}

struct HourlyDetailRow: View {
    let hourIndex: Int
    let hourlyRecord: HourlyRecord
    
    var body: some View {
        HStack {
            Text("\(hourIndex + 1)시간차")
                .font(.caption2)
                .frame(width: 60, alignment: .leading)
            
            if hourlyRecord.sojuBottles > 0 || hourlyRecord.sojuShots > 0 {
                HStack(spacing: 2) {
                    ImageLiterals.soju
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("\(hourlyRecord.sojuBottles)병 \(hourlyRecord.sojuShots)잔")
                        .font(.caption2)
                }
            }
            
            if hourlyRecord.beerBottles > 0 || hourlyRecord.beerGlasses > 0 {
                HStack(spacing: 2) {
                    ImageLiterals.beer
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("\(hourlyRecord.beerBottles)병 \(hourlyRecord.beerGlasses)잔")
                        .font(.caption2)
                }
            }
            
            if hourlyRecord.somaekGlasses > 0 {
                HStack(spacing: 2) {
                    ImageLiterals.somek
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("\(hourlyRecord.somaekGlasses)잔")
                        .font(.caption2)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    RecordView(store: Store(initialState: RecordsFeature.State()) {
        RecordsFeature()
    })
}
