import XCTest
@testable import EudamedRest
@testable import EudamedClient

final class RemoteActorRepositoryTests: XCTestCase {

    func testSearchMapsFieldsToActor() async throws {
        let client = try makeClient("""
        {
          "value": [{
            "ACTOR_ID": "aaaa-1111",
            "NAME": "Acme Medical GmbH",
            "ABBREVIATED_NAME": "Acme",
            "ACTOR_TYPE": "refdata.actor-type.manufacturer",
            "ACT_COUNTRY_ISO2_CODE": "DE"
          }]
        }
        """)
        let repo = RemoteActorRepository(client: client)

        let actors = try await repo.search(query: ActorQuery(name: "Acme"))

        XCTAssertEqual(actors.count, 1)
        let actor = try XCTUnwrap(actors.first)
        XCTAssertEqual(actor.id, "aaaa-1111")
        XCTAssertEqual(actor.name, "Acme Medical GmbH")
        XCTAssertEqual(actor.abbreviatedName, "Acme")
        XCTAssertEqual(actor.actorType, "refdata.actor-type.manufacturer")
        XCTAssertEqual(actor.countryIso2Code, "DE")
    }

    func testActorByIdReturnsMatchingActor() async throws {
        let client = try makeClient("""
        {"value": [{"ACTOR_ID": "bbbb-2222", "NAME": "Beta Corp"}]}
        """)
        let repo = RemoteActorRepository(client: client)

        let actor = try await repo.actor(id: "bbbb-2222")

        XCTAssertEqual(actor?.id, "bbbb-2222")
        XCTAssertEqual(actor?.name, "Beta Corp")
    }

    func testActorByIdReturnsNilWhenNotFound() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = RemoteActorRepository(client: client)

        let actor = try await repo.actor(id: "unknown")

        XCTAssertNil(actor)
    }

    func testSearchFollowsPagination() async throws {
        let cursor = "page2cursor"
        let client = try makePaginatingClient(
            firstPage: """
            {
              "value": [{"ACTOR_ID": "aaa-1", "NAME": "Alpha Corp"}],
              "nextLink": "https://example.com/actors?\\u0024after=\(cursor)"
            }
            """,
            secondPage: #"{"value": [{"ACTOR_ID": "aaa-2", "NAME": "Beta Corp"}]}"#
        )
        let repo = RemoteActorRepository(client: client)

        let actors = try await repo.search(query: ActorQuery())

        XCTAssertEqual(actors.map(\.id), ["aaa-1", "aaa-2"])
    }
}
