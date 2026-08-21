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

    func testSearchReturnsEmptyArrayWhenResponseHasNoItems() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = RemoteReferenceRepository(client: client)

        let entries = try await repo.search(query: ReferenceQuery())

        XCTAssertTrue(entries.isEmpty)
    }

    func testSearchReturnsMultipleEntries() async throws {
        let client = try makeClient("""
        {
          "value": [
            {"ID": 1, "CODE": "refdata.risk-class.class-i",   "LANGUAGE": "en", "VALUE": "Class I"},
            {"ID": 2, "CODE": "refdata.risk-class.class-iia", "LANGUAGE": "en", "VALUE": "Class IIa"},
            {"ID": 3, "CODE": "refdata.risk-class.class-iib", "LANGUAGE": "en", "VALUE": "Class IIb"}
          ]
        }
        """)
        let repo = RemoteReferenceRepository(client: client)

        let entries = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class"))

        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.map(\.id), [1, 2, 3])
    }

    func testSearchFiltersEntriesWithMissingId() async throws {
        let client = try makeClient("""
        {
          "value": [
            {"ID": 10, "CODE": "valid-code", "LANGUAGE": "en", "VALUE": "Valid"},
            {"CODE": "missing-id", "LANGUAGE": "en", "VALUE": "No ID here"}
          ]
        }
        """)
        let repo = RemoteReferenceRepository(client: client)

        let entries = try await repo.search(query: ReferenceQuery())

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.id, 10)
    }

    func testSearchDefaultsNullOptionalFieldsToEmptyString() async throws {
        let client = try makeClient(#"{"value": [{"ID": 99}]}"#)
        let repo = RemoteReferenceRepository(client: client)

        let entries = try await repo.search(query: ReferenceQuery())

        let entry = try XCTUnwrap(entries.first)
        XCTAssertEqual(entry.id, 99)
        XCTAssertEqual(entry.code, "")
        XCTAssertEqual(entry.language, "")
        XCTAssertEqual(entry.value, "")
    }

    func testSearchFollowsPagination() async throws {
        let cursor = "ref-cursor-page2"
        let client = try makePaginatingClient(
            firstPage: """
            {
              "value": [{"ID": 1, "CODE": "ref.code.a", "LANGUAGE": "en", "VALUE": "A"}],
              "nextLink": "https://example.com/reference?\\u0024after=\(cursor)"
            }
            """,
            secondPage: #"{"value": [{"ID": 2, "CODE": "ref.code.b", "LANGUAGE": "en", "VALUE": "B"}]}"#
        )
        let repo = RemoteReferenceRepository(client: client)

        let entries = try await repo.search(query: ReferenceQuery())

        XCTAssertEqual(entries.map(\.id), [1, 2])
        XCTAssertEqual(entries.map(\.value), ["A", "B"])
    }

    func testSearchIncludesCodeQueryParameter() async throws {
        let transport = MockRestTransport(responseBody: #"{"value": []}"#)
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)
        let repo = RemoteReferenceRepository(client: client)

        _ = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-iii"))

        let path = try XCTUnwrap(transport.capturedRequests.first?.path)
        XCTAssertTrue(path.contains("CODE=refdata.risk-class.class-iii"), "Expected CODE in path, got: \(path)")
    }

    func testSearchIncludesLanguageQueryParameter() async throws {
        let transport = MockRestTransport(responseBody: #"{"value": []}"#)
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)
        let repo = RemoteReferenceRepository(client: client)

        _ = try await repo.search(query: ReferenceQuery(language: "fr"))

        let path = try XCTUnwrap(transport.capturedRequests.first?.path)
        XCTAssertTrue(path.contains("LANGUAGE=fr"), "Expected LANGUAGE=fr in path, got: \(path)")
    }

    func testSearchOmitsIdWhenNil() async throws {
        let transport = MockRestTransport(responseBody: #"{"value": []}"#)
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)
        let repo = RemoteReferenceRepository(client: client)

        _ = try await repo.search(query: ReferenceQuery(id: nil))

        let path = try XCTUnwrap(transport.capturedRequests.first?.path)
        XCTAssertFalse(path.contains("ID="), "Expected ID omitted from path, got: \(path)")
    }

    func testSearchIncludesIdQueryParameterWhenNonZero() async throws {
        let transport = MockRestTransport(responseBody: #"{"value": []}"#)
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)
        let repo = RemoteReferenceRepository(client: client)

        _ = try await repo.search(query: ReferenceQuery(id: 42))

        let path = try XCTUnwrap(transport.capturedRequests.first?.path)
        XCTAssertTrue(path.contains("ID="), "Expected ID in path, got: \(path)")
    }

    func testGetReferenceValueReturnsValueOfFirstMatch() async throws {
        let client = try makeClient("""
        {
          "value": [{"ID": 5, "CODE": "refdata.risk-class.class-i", "LANGUAGE": "de", "VALUE": "Klasse I"}]
        }
        """)
        let repo = RemoteReferenceRepository(client: client)

        let value = await repo.getReferenceValue(id: 5, code: "refdata.risk-class.class-i", language: "de")

        XCTAssertEqual(value, "Klasse I")
    }

    func testGetReferenceValueReturnsNilWhenNoResults() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = RemoteReferenceRepository(client: client)

        let value = await repo.getReferenceValue(id: 999, code: "unknown.code", language: "en")

        XCTAssertNil(value)
    }
}
