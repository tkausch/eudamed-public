import XCTest
import SwiftData
@testable import EudamedClient

@MainActor
final class LocalActorRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repo: LocalActorRepository!

    override func setUp() async throws {
        container = try ModelContainer(
            for: Actor.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repo = LocalActorRepository(modelContainer: container)
    }

    override func tearDown() async throws {
        repo = nil
        container = nil
    }

    private func insert(_ actors: Actor...) throws {
        actors.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
    }

    func testSearchReturnsAllWhenQueryIsEmpty() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Alpha"
        let a2 = Actor(actorId: "id-2"); a2.name = "Beta"
        try insert(a1, a2)

        let results = try await repo.search()

        XCTAssertEqual(results.count, 2)
    }

    func testSearchFiltersByActorId() async throws {
        try insert(Actor(actorId: "id-1"), Actor(actorId: "id-2"))

        let results = try await repo.search(query: ActorQuery(actorId: "id-1"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchFiltersByName() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Acme"
        let a2 = Actor(actorId: "id-2"); a2.name = "Beta"
        try insert(a1, a2)

        let results = try await repo.search(query: ActorQuery(name: "Acme"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchFiltersByActorType() async throws {
        let a1 = Actor(actorId: "id-1"); a1.actorType = "refdata.actor-type.manufacturer"
        let a2 = Actor(actorId: "id-2"); a2.actorType = "refdata.actor-type.authorized-rep"
        try insert(a1, a2)

        let results = try await repo.search(query: ActorQuery(actorType: "refdata.actor-type.manufacturer"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchFiltersByCountryIso2Code() async throws {
        let a1 = Actor(actorId: "id-1"); a1.countryIso2Code = "DE"
        let a2 = Actor(actorId: "id-2"); a2.countryIso2Code = "FR"
        try insert(a1, a2)

        let results = try await repo.search(query: ActorQuery(countryIso2Code: "DE"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchReturnsEmptyWhenNoMatch() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Acme"
        try insert(a1)

        let results = try await repo.search(query: ActorQuery(name: "Unknown"))

        XCTAssertTrue(results.isEmpty)
    }

    func testActorByIdReturnsMatchingActor() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Acme Medical GmbH"
        try insert(a1)

        let actor = try await repo.actor(id: "id-1")

        XCTAssertEqual(actor?.id, "id-1")
        XCTAssertEqual(actor?.name, "Acme Medical GmbH")
    }

    func testActorByIdReturnsNilWhenNotFound() async throws {
        try insert(Actor(actorId: "id-1"))

        let actor = try await repo.actor(id: "unknown")

        XCTAssertNil(actor)
    }
}
