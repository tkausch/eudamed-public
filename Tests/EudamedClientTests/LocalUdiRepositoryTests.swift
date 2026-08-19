import XCTest
import SwiftData
@testable import EudamedClient

@MainActor
final class LocalUdiRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repo: LocalUdiDevicesRepository!

    override func setUp() async throws {
        container = try ModelContainer(
            for: UdiDevice.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repo = LocalUdiDevicesRepository(modelContainer: container)
    }

    override func tearDown() async throws {
        repo = nil
        container = nil
    }

    private func insert(_ devices: UdiDevice...) throws {
        devices.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
    }

    func testSearchReturnsAllWhenQueryIsEmpty() async throws {
        try insert(UdiDevice(primaryDi: "DI-001"), UdiDevice(primaryDi: "DI-002"))

        let results = try await repo.search()

        XCTAssertEqual(results.count, 2)
    }

    func testSearchFiltersByPrimaryDi() async throws {
        try insert(UdiDevice(primaryDi: "DI-001"), UdiDevice(primaryDi: "DI-002"))

        let results = try await repo.search(query: UdiDevicesQuery(primaryDi: "DI-001"))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchFiltersByTradeName() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.tradeName = "Acme Scanner Pro"
        let d2 = UdiDevice(primaryDi: "DI-002"); d2.tradeName = "Beta Probe"
        try insert(d1, d2)

        let results = try await repo.search(query: UdiDevicesQuery(tradeName: "Acme Scanner Pro"))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchFiltersByMfSrn() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.mfSrn = "DE-MF-000012345"
        let d2 = UdiDevice(primaryDi: "DI-002"); d2.mfSrn = "FR-MF-000099999"
        try insert(d1, d2)

        let results = try await repo.search(query: UdiDevicesQuery(mfSrn: "DE-MF-000012345"))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchFiltersByRiskClassId() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.riskClassId = 3
        let d2 = UdiDevice(primaryDi: "DI-002"); d2.riskClassId = 1
        try insert(d1, d2)

        let results = try await repo.search(query: UdiDevicesQuery(riskClassId: 3))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchReturnsEmptyWhenNoMatch() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.tradeName = "Acme"
        try insert(d1)

        let results = try await repo.search(query: UdiDevicesQuery(tradeName: "Unknown"))

        XCTAssertTrue(results.isEmpty)
    }

    func testDeviceByPrimaryDiReturnsMatchingDevice() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.tradeName = "Acme Scanner Pro"
        try insert(d1)

        let device = try await repo.device(primaryDi: "DI-001")

        XCTAssertEqual(device?.id, "DI-001")
        XCTAssertEqual(device?.tradeName, "Acme Scanner Pro")
    }

    func testDeviceByPrimaryDiReturnsNilWhenNotFound() async throws {
        try insert(UdiDevice(primaryDi: "DI-001"))

        let device = try await repo.device(primaryDi: "unknown")

        XCTAssertNil(device)
    }
}
