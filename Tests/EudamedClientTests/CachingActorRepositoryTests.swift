import XCTest
import SwiftData
@testable import EudamedRest
@testable import EudamedClient

@MainActor
final class CachingActorRepositoryTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(
            for: Actor.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() async throws {
        container = nil
    }

    func testSyncAndSearchReturnsInjectedActor() async throws {
        let client = try makeClient("""
        {"value": [{"ACTOR_ID": "aaaa-1111", "NAME": "Acme Medical GmbH", "ACT_COUNTRY_ISO2_CODE": "DE"}]}
        """)
        let repo = CachingActorRepository(
            modelContainer: container,
            remote: RemoteActorRepository(client: client)
        )

        try await repo.sync()
        let results = try await repo.search()

        XCTAssertEqual(results.count, 1)
        let actor = try XCTUnwrap(results.first)
        XCTAssertEqual(actor.id, "aaaa-1111")
        XCTAssertEqual(actor.name, "Acme Medical GmbH")
        XCTAssertEqual(actor.countryIso2Code, "DE")
    }

    func testSyncSetsLastSync() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = CachingActorRepository(
            modelContainer: container,
            remote: RemoteActorRepository(client: client)
        )

        let before = await repo.lastSync
        try await repo.sync()
        let after = await repo.lastSync

        XCTAssertNil(before)
        XCTAssertNotNil(after)
    }
}
