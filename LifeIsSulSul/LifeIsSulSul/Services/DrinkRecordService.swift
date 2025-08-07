import Foundation
import ComposableArchitecture

protocol DrinkRecordServiceProtocol: Sendable {
    func loadRecords() async -> [DrinkRecord]
    func saveRecord(_ record: DrinkRecord) async
    func saveRecords(_ records: [DrinkRecord]) async
    func saveTempRecord(_ record: DrinkRecord) async
    func loadTempRecord() async -> DrinkRecord?
    func clearTempRecord() async
}

struct DrinkRecordService: DrinkRecordServiceProtocol {
    private let userDefaults: UserDefaults
    private let recordsKey = "drinkRecords"
    private let tempRecordKey = "tempDrinkRecord"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    @MainActor
    func loadRecords() async -> [DrinkRecord] {
        print("🔍 \(#function) - 시작")
        
        guard let data = userDefaults.data(forKey: recordsKey) else {
            print("🔍 \(#function) - UserDefaults에 데이터가 없음")
            return []
        }
        
        print("🔍 \(#function) - 데이터 크기: \(data.count) bytes")
        
        do {
            let records = try JSONDecoder().decode([DrinkRecord].self, from: data)
            print("🔍 \(#function) - 성공적으로 \(records.count)개 레코드 로드")
            return records
        } catch {
            print("🔍 \(#function) - 디코딩 실패: \(error)")
            return []
        }
    }
    
    func saveRecord(_ record: DrinkRecord) async {
        print("💾 \(#function) - 시작")
        let records = await loadRecords()
        var newRecords = records
        newRecords.append(record)
        await saveRecords(newRecords)
    }
    
    @MainActor
    func saveRecords(_ records: [DrinkRecord]) async {
        print("💾 \(#function) - \(records.count)개 레코드 저장 시작")
        
        do {
            let encoded = try JSONEncoder().encode(records)
            userDefaults.set(encoded, forKey: recordsKey)
            print("💾 \(#function) - 저장 성공: \(encoded.count) bytes")
        } catch {
            print("💾 \(#function) - 인코딩 실패: \(error)")
        }
    }
    
    @MainActor
    func saveTempRecord(_ record: DrinkRecord) async {
        print("💾 \(#function) - 임시 레코드 저장")
        
        do {
            let encoded = try JSONEncoder().encode(record)
            userDefaults.set(encoded, forKey: tempRecordKey)
            print("💾 \(#function) - 임시 저장 성공")
        } catch {
            print("💾 \(#function) - 임시 저장 인코딩 실패: \(error)")
        }
    }
    
    @MainActor
    func loadTempRecord() async -> DrinkRecord? {
        print("🔍 \(#function) - 임시 레코드 로드")
        
        guard let data = userDefaults.data(forKey: tempRecordKey) else {
            print("🔍 \(#function) - 임시 레코드 없음")
            return nil
        }
        
        do {
            let record = try JSONDecoder().decode(DrinkRecord.self, from: data)
            print("🔍 \(#function) - 임시 레코드 로드 성공")
            return record
        } catch {
            print("🔍 \(#function) - 임시 레코드 디코딩 실패: \(error)")
            return nil
        }
    }
    
    @MainActor
    func clearTempRecord() async {
        print("🗑️ \(#function) - 임시 레코드 삭제")
        userDefaults.removeObject(forKey: tempRecordKey)
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
