import HTTPTypes
import XCTest

@testable import EudamedClient

final class EudamedClientTests: XCTestCase {

    // MARK: - Client construction

    func testClientCanBeInitialized() throws {
        XCTAssertNoThrow(try Client())
    }

    func testDefaultServerURL() throws {
        let url = try Servers.Server1.url()
        XCTAssertEqual(url.absoluteString, "https://api.datalake.sante.service.ec.europa.eu/eudamed")
    }

    // MARK: - getActors

    func testGetActorsSendsExpectedRequestAndDecodesResponse() async throws {
        let transport = MockClientTransport(
            responseBody: """
            {
              "value": [
                {
                  "ACTOR_ID": "11111111-1111-1111-1111-111111111111",
                  "NAME": "Acme Medical GmbH",
                  "ACTOR_TYPE": "refdata.actor-type.manufacturer",
                  "ACT_COUNTRY_ISO2_CODE": "DE"
                }
              ]
            }
            """
        )
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)

        let output = try await client.getActors(.init(query: .init(NAME: "Acme")))

        XCTAssertEqual(transport.capturedRequest?.method, .get)
        XCTAssertEqual(transport.capturedRequest?.path?.hasPrefix("/actors"), true)
        XCTAssertEqual(transport.capturedRequest?.path?.contains("NAME=Acme"), true)

        let actors = try output.ok.body.json.value ?? []
        XCTAssertEqual(actors.count, 1)
        XCTAssertEqual(actors.first?.NAME, "Acme Medical GmbH")
        XCTAssertEqual(actors.first?.ACT_COUNTRY_ISO2_CODE, "DE")
    }

    // MARK: - getReference

    func testGetReferenceSendsExpectedRequestAndDecodesResponse() async throws {
        let transport = MockClientTransport(
            responseBody: """
            {
              "value": [
                {
                  "ID": 42,
                  "CODE": "refdata.risk-class.class-iii",
                  "LANGUAGE": "en",
                  "VALUE": "Class III"
                }
              ]
            }
            """
        )
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)

        let output = try await client.getReference(.init(query: .init(CODE: "refdata.risk-class.class-iii")))

        XCTAssertEqual(transport.capturedRequest?.method, .get)
        XCTAssertEqual(transport.capturedRequest?.path?.hasPrefix("/reference"), true)

        let entries = try output.ok.body.json.value ?? []
        XCTAssertEqual(entries.first?.CODE, "refdata.risk-class.class-iii")
        XCTAssertEqual(entries.first?.VALUE, "Class III")
    }

    // MARK: - getUdi

    func testGetUdiSendsExpectedRequestAndDecodesResponse() async throws {
        let transport = MockClientTransport(
            responseBody: """
            {
              "value": [
                {
                  "UUID": "22222222-2222-2222-2222-222222222222",
                  "PRIMARY_DI": "(01)04012345123456",
                  "TRADE_NAME": "Acme Scanner",
                  "MF_SRN": "DE-MF-000012345",
                  "MF_NAME": "Acme Medical GmbH",
                  "RISK_CLASS_ID": 3
                }
              ]
            }
            """
        )
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)

        let output = try await client.getUdi(.init(query: .init(PRIMARY_DI: "(01)04012345123456")))

        XCTAssertEqual(transport.capturedRequest?.method, .get)
        XCTAssertEqual(transport.capturedRequest?.path?.hasPrefix("/udi"), true)

        let devices = try output.ok.body.json.value ?? []
        XCTAssertEqual(devices.first?.TRADE_NAME, "Acme Scanner")
        XCTAssertEqual(devices.first?.MF_SRN, "DE-MF-000012345")
        XCTAssertEqual(devices.first?.RISK_CLASS_ID, 3)
    }

    // MARK: - Pagination

    func testNextLinkIsDecodedFromResponse() async throws {
        let cursor = "W3siRW50aXR5TmFtZSI6IkVVREFNRURTQ0hfVURJX0RJX0RBVEFfUFVCTElDX1ZJRVciLCJGaWVsZE5hbWUiOiJoYXNoX2NvbHVtbiIsIkZpZWxkVmFsdWUiOiJBQlNZc3FJL0Z4UHF0bmNHOTlvdk9XejRVYVE9IiwiRGlyZWN0aW9uIjowfV0="
        let transport = MockClientTransport(
            responseBody: """
            {
              "value": [],
              "nextLink": "https://api.datalake.sante.service.ec.europa.eu/eudamed/udi?$after=\(cursor)&format=json&api-version=v1.0"
            }
            """
        )
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)

        let output = try await client.getUdi(.init(query: .init()))
        let body = try output.ok.body.json

        XCTAssertNotNil(body.nextLink)
        let nextLinkURL = try XCTUnwrap(URL(string: body.nextLink!))
        let afterValue = URLComponents(url: nextLinkURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "$after" })?.value
        XCTAssertEqual(afterValue, cursor)
    }

  

    func testAfterCursorIsSentInRequest() async throws {
        let cursor = "W3siRW50aXR5TmFtZSI6IkVVREFNRURTQ0hfVURJX0RJX0RBVEFfUFVCTElDX1ZJRVciLCJGaWVsZE5hbWUiOiJoYXNoX2NvbHVtbiIsIkZpZWxkVmFsdWUiOiJBQlNZc3FJL0Z4UHF0bmNHOTlvdk9XejRVYVE9IiwiRGlyZWN0aW9uIjowfV0="
        let transport = MockClientTransport(responseBody: #"{"value":[]}"#)
        let client = Client(serverURL: try Servers.Server1.url(), transport: transport)

        _ = try await client.getUdi(.init(query: .init(_dollar_after: cursor)))

        let path = try XCTUnwrap(transport.capturedRequest?.path)
        XCTAssertTrue(path.contains("%24after="), "Expected percent-encoded $after in request path, got: \(path)")
    }
}
