import SwiftUI
import ComposableArchitecture

enum SortOrder: String, CaseIterable, Sendable {
    case newest = "최신순"
    case oldest = "과거순"
}

struct RecordsFeature: Reducer {
    struct State: Equatable {
        var records: [DrinkRecord] = []
        var sortOrder: SortOrder = .newest
        var isLoading = false
        
        var sortedRecords: [DrinkRecord] {
            switch sortOrder {
            case .newest:
                return records.sorted { $0.date > $1.date }
            case .oldest:
                return records.sorted { $0.date < $1.date }
            }
        }
    }
    
    enum Action {
        case loadRecords
        case recordsLoaded([DrinkRecord])
        case setSortOrder(SortOrder)
        case deleteRecord(IndexSet)
        case refresh
    }
    
    @Dependency(\.drinkRecordService) var drinkRecordService
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadRecords:
                state.isLoading = true
                
                return .run { send in
                    let records = await drinkRecordService.loadRecords()
                    await send(.recordsLoaded(records))
                }
                
            case let .recordsLoaded(records):
                state.records = records
                state.isLoading = false
                return .none
                
            case let .setSortOrder(sortOrder):
                state.sortOrder = sortOrder
                return .none
                
            case let .deleteRecord(indexSet):
                let sortedRecords = state.sortedRecords
                for index in indexSet {
                    if let recordIndex = state.records.firstIndex(where: { $0.id == sortedRecords[index].id }) {
                        state.records.remove(at: recordIndex)
                    }
                }
                
                return .run { [records = state.records] send in
                    await drinkRecordService.saveRecords(records)
                }
                
            case .refresh:
                return .send(.loadRecords)
            }
        }
    }
}
