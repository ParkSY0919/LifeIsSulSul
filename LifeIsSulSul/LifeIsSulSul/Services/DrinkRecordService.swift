import Foundation
import ComposableArchitecture

protocol DrinkRecordServiceProtocol: Sendable {
    func loadRecords() -> [DrinkRecord]
    func saveRecord(_ record: DrinkRecord)
    func saveRecords(_ records: [DrinkRecord])
}

struct DrinkRecordService: DrinkRecordServiceProtocol {
    private let userDefaults: UserDefaults
    private let recordsKey = "drinkRecords"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func loadRecords() -> [DrinkRecord] {
        guard let data = userDefaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([DrinkRecord].self, from: data) else {
            return []
        }
        return records
    }
    
    func saveRecord(_ record: DrinkRecord) {
        var records = loadRecords()
        records.append(record)
        saveRecords(records)
    }
    
    func saveRecords(_ records: [DrinkRecord]) {
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }
}

// TCA 호환 의존성 키
extension DependencyValues {
    var drinkRecordService: DrinkRecordServiceProtocol {
        get { self[DrinkRecordServiceKey.self] }
        set { self[DrinkRecordServiceKey.self] = newValue }
    }
    
    var userDefaults: UserDefaults {
        get { self[UserDefaultsKey.self] }
        set { self[UserDefaultsKey.self] = newValue }
    }
}

private enum DrinkRecordServiceKey: DependencyKey {
    static let liveValue: DrinkRecordServiceProtocol = DrinkRecordService()
}

extension UserDefaults: @unchecked @retroactive Sendable {}

private enum UserDefaultsKey: DependencyKey {
    static let liveValue: UserDefaults = .standard
}
