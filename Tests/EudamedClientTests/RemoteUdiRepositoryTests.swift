import XCTest
@testable import EudamedRest
@testable import EudamedClient

final class RemoteUdiRepositoryTests: XCTestCase {

    func testSearchMapsFieldsToUdiDevice() async throws {
        let client = try makeClient("""
        {
          "value": [{
            "PRIMARY_DI": "(01)04012345123456",
            "BASIC_UDI": "BASIC-001",
            "TRADE_NAME": "Acme Scanner Pro",
            "DEVICE_MODEL": "AS-2000",
            "MF_SRN": "DE-MF-000012345",
            "MF_NAME": "Acme Medical GmbH",
            "RISK_CLASS_ID": 3,
            "APPLICABLE_LEGISLATION_ID": 2,
            "IMPLANTABLE": 0,
            "STERILE": 1
          }]
        }
        """)
        let repo = RemoteUdiDevicesRepository(client: client)

        let devices = try await repo.search(query: UdiDevicesQuery(tradeName: "Acme"))

        XCTAssertEqual(devices.count, 1)
        let device = try XCTUnwrap(devices.first)
        XCTAssertEqual(device.id, "(01)04012345123456")
        XCTAssertEqual(device.basicUdi, "BASIC-001")
        XCTAssertEqual(device.tradeName, "Acme Scanner Pro")
        XCTAssertEqual(device.deviceModel, "AS-2000")
        XCTAssertEqual(device.mfSrn, "DE-MF-000012345")
        XCTAssertEqual(device.mfName, "Acme Medical GmbH")
        XCTAssertEqual(device.riskClassId, 3)
        XCTAssertEqual(device.applicableLegislationId, 2)
        XCTAssertEqual(device.implantable, 0)
        XCTAssertEqual(device.sterile, 1)
    }

    func testDeviceByPrimaryDiReturnsMatch() async throws {
        let client = try makeClient("""
        {"value": [{"PRIMARY_DI": "(01)04012345123456", "TRADE_NAME": "Scanner"}]}
        """)
        let repo = RemoteUdiDevicesRepository(client: client)

        let device = try await repo.device(primaryDi: "(01)04012345123456")

        XCTAssertEqual(device?.id, "(01)04012345123456")
        XCTAssertEqual(device?.tradeName, "Scanner")
    }

    func testDeviceByPrimaryDiReturnsNilWhenNotFound() async throws {
        let client = try makeClient(#"{"value": []}"#)
        let repo = RemoteUdiDevicesRepository(client: client)

        let device = try await repo.device(primaryDi: "unknown")

        XCTAssertNil(device)
    }

    func testSearchFollowsPagination() async throws {
        let cursor = "udipage2"
        let client = try makePaginatingClient(
            firstPage: """
            {
              "value": [{"PRIMARY_DI": "DI-001"}],
              "nextLink": "https://example.com/udi?\\u0024after=\(cursor)"
            }
            """,
            secondPage: #"{"value": [{"PRIMARY_DI": "DI-002"}]}"#
        )
        let repo = RemoteUdiDevicesRepository(client: client)

        let devices = try await repo.search(query: UdiDevicesQuery())

        XCTAssertEqual(devices.map(\.id), ["DI-001", "DI-002"])
    }
}
