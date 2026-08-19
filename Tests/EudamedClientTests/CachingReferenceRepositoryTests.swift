import XCTest
import SwiftData
@testable import EudamedRest
@testable import EudamedClient

@MainActor
final class CachingReferenceRepositoryTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(
            for: ReferenceEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() async throws {
        container = nil
    }

    func testSyncAndSearchReturnsInjectedEntry() async throws {
        let client = try makeClient("""
        {"value": [{"ID": 42, "CODE": "refdata.risk-class.class-iii", "LANGUAGE": "en", "VALUE": "Class III"}]}
        """)
        let repo = CachingReferenceRepository(
            modelContainer: container,
            remote: RemoteReferenceRepository(client: client)
        )

        try await repo.sync()
        let results = try await repo.search()

        XCTAssertEqual(results.count, 1)
        let entry = try XCTUnwrap(results.first)
        XCTAssertEqual(entry.id, 42)
        XCTAssertEqual(entry.code, "refdata.risk-class.class-iii")
        XCTAssertEqual(entry.language, "en")
        XCTAssertEqual(entry.value, "Class III")
    }

    func testSyncSetsLastSync() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = CachingReferenceRepository(
            modelContainer: container,
            remote: RemoteReferenceRepository(client: client)
        )

        let before = await repo.lastSync
        try await repo.sync()
        let after = await repo.lastSync

        XCTAssertNil(before)
        XCTAssertNotNil(after)
    }
}
