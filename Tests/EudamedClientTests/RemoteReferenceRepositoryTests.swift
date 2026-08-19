import XCTest
@testable import EudamedRest
@testable import EudamedClient

final class RemoteReferenceRepositoryTests: XCTestCase {

    func testSearchMapsFieldsToReferenceEntry() async throws {
        let client = try makeClient("""
        {
          "value": [{
            "ID": 42,
            "CODE": "refdata.risk-class.class-iii",
            "LANGUAGE": "en",
            "VALUE": "Class III"
          }]
        }
        """)
        let repo = RemoteReferenceRepository(client: client)

        let entries = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-iii"))

        XCTAssertEqual(entries.count, 1)
        let entry = try XCTUnwrap(entries.first)
        XCTAssertEqual(entry.id, 42)
        XCTAssertEqual(entry.code, "refdata.risk-class.class-iii")
        XCTAssertEqual(entry.language, "en")
        XCTAssertEqual(entry.value, "Class III")
    }

    func testEntryByIdReturnsMatch() async throws {
        let client = try makeClient("""
        {"value": [{"ID": 7, "CODE": "refdata.actor-type.manufacturer", "VALUE": "Manufacturer"}]}
        """)
        let repo = RemoteReferenceRepository(client: client)

        let entry = try await repo.entry(id: 7)

        XCTAssertEqual(entry?.id, 7)
        XCTAssertEqual(entry?.value, "Manufacturer")
    }

    func testEntryByIdReturnsNilWhenNotFound() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = RemoteReferenceRepository(client: client)

        let entry = try await repo.entry(id: 999)

        XCTAssertNil(entry)
    }

    func testSearchFollowsPagination() async throws {
        let cursor = "refpage2"
        let client = try makePaginatingClient(
            firstPage: """
            {
              "value": [{"ID": 1, "CODE": "code.a", "VALUE": "A"}],
              "nextLink": "https://example.com/reference?\\u0024after=\(cursor)"
            }
            """,
            secondPage: #"{"value": [{"ID": 2, "CODE": "code.b", "VALUE": "B"}]}"#
        )
        let repo = RemoteReferenceRepository(client: client)

        let entries = try await repo.search(query: ReferenceQuery())

        XCTAssertEqual(entries.map(\.id), [1, 2])
        XCTAssertEqual(entries.map(\.value), ["A", "B"])
    }
}
