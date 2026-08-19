import XCTest
import SwiftData
@testable import EudamedRest
@testable import EudamedClient

@MainActor
final class CachingUdiDeviceRepositoryTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(
            for: UdiDevice.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() async throws {
        container = nil
    }

    func testSyncAndSearchReturnsInjectedDevice() async throws {
        let client = try makeClient("""
        {"value": [{"PRIMARY_DI": "DI-001", "TRADE_NAME": "Acme Scanner Pro"}]}
        """)
        let repo = CachingUdiDeviceRepository(
            modelContainer: container,
            remote: RemoteUdiDevicesRepository(client: client)
        )

        try await repo.sync()
        let results = try await repo.search()

        XCTAssertEqual(results.count, 1)
        let device = try XCTUnwrap(results.first)
        XCTAssertEqual(device.id, "DI-001")
        XCTAssertEqual(device.tradeName, "Acme Scanner Pro")
    }

    func testSyncSetsLastSync() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = CachingUdiDeviceRepository(
            modelContainer: container,
            remote: RemoteUdiDevicesRepository(client: client)
        )

        let before = await repo.lastSync
        try await repo.sync()
        let after = await repo.lastSync

        XCTAssertNil(before)
        XCTAssertNotNil(after)
    }
}
