import Foundation
import ComposableArchitecture

protocol DrinkRecordServiceProtocol: Sendable {
    func loadRecords() async -> [DrinkRecord]
    func saveRecord(_ record: DrinkRecord) async
    func saveRecords(_ records: [DrinkRecord]) async
}

struct DrinkRecordService: DrinkRecordServiceProtocol {
    private let userDefaults: UserDefaults
    private let recordsKey = "drinkRecords"
    
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
    
    // 개발/테스트용 더미 데이터 생성
//    @MainActor
//    func createTestData() async {
//        print("🧪 \(#function) - 테스트 데이터 생성 중")
//        
//        let testRecords = [
//            DrinkRecord(
//                date: Date().addingTimeInterval(-86400), // 1일 전
//                sojuBottles: 1,
//                sojuShots: 3,
//                beerBottles: 2,
//                beerGlasses: 1,
//                somaekGlasses: 4,
//                hourlyPace: [
//                    HourlyRecord(hour: 1, sojuBottles: 0, sojuShots: 8, beerBottles: 1, beerGlasses: 2, somaekGlasses: 2),
//                    HourlyRecord(hour: 2, sojuBottles: 1, sojuShots: 3, beerBottles: 1, beerGlasses: 3, somaekGlasses: 2)
//                ],
//                totalDuration: 7200 // 2시간
//            ),
//            DrinkRecord(
//                date: Date().addingTimeInterval(-172800), // 2일 전
//                sojuBottles: 0,
//                sojuShots: 5,
//                beerBottles: 1,
//                beerGlasses: 2,
//                somaekGlasses: 1,
//                hourlyPace: [
//                    HourlyRecord(hour: 1, sojuBottles: 0, sojuShots: 5, beerBottles: 1, beerGlasses: 2, somaekGlasses: 1)
//                ],
//                totalDuration: 3600 // 1시간
//            )
//        ]
//        
//        await saveRecords(testRecords)
//        print("🧪 \(#function) - \(testRecords.count)개 테스트 데이터 생성 완료")
//    }
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
