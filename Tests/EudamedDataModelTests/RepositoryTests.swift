import XCTest
import SwiftData
@testable import EudamedClient
@testable import EudamedDataModel

// MARK: - Helpers

private func makeClient(_ body: String) throws -> Client {
    Client(serverURL: try Servers.Server1.url(), transport: MockClientTransport(responseBody: body))
}

private func makePaginatingClient(firstPage: String, secondPage: String) throws -> Client {
    var callCount = 0
    return Client(
        serverURL: try Servers.Server1.url(),
        transport: MockClientTransport {
            defer { callCount += 1 }
            return callCount == 0 ? firstPage : secondPage
        }
    )
}

// MARK: - ActorRepository

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
              "value": [{"ACTOR_ID": "aaa-1"}],
              "nextLink": "https://example.com/actors?\\u0024after=\(cursor)"
            }
            """,
            secondPage: #"{"value": [{"ACTOR_ID": "aaa-2"}]}"#
        )
        let repo = RemoteActorRepository(client: client)

        let actors = try await repo.search(query: ActorQuery())

        XCTAssertEqual(actors.map(\.id), ["aaa-1", "aaa-2"])
    }
}

// MARK: - UdiRepository

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

// MARK: - ReferenceRepository

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

// MARK: - LocalActorRepository

@MainActor
final class LocalActorRepositoryTests: XCTestCase {

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

    private func insert(_ actors: Actor...) throws {
        actors.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
    }

    private func makeRepo() -> LocalActorRepository {
        LocalActorRepository(modelContainer: container)
    }

    func testSearchReturnsAllWhenQueryIsEmpty() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Alpha"
        let a2 = Actor(actorId: "id-2"); a2.name = "Beta"
        try insert(a1, a2)

        let results = try await makeRepo().search()

        XCTAssertEqual(results.count, 2)
    }

    func testSearchFiltersByActorId() async throws {
        try insert(Actor(actorId: "id-1"), Actor(actorId: "id-2"))

        let results = try await makeRepo().search(query: ActorQuery(actorId: "id-1"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchFiltersByName() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Acme"
        let a2 = Actor(actorId: "id-2"); a2.name = "Beta"
        try insert(a1, a2)

        let results = try await makeRepo().search(query: ActorQuery(name: "Acme"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchFiltersByActorType() async throws {
        let a1 = Actor(actorId: "id-1"); a1.actorType = "refdata.actor-type.manufacturer"
        let a2 = Actor(actorId: "id-2"); a2.actorType = "refdata.actor-type.authorized-rep"
        try insert(a1, a2)

        let results = try await makeRepo().search(query: ActorQuery(actorType: "refdata.actor-type.manufacturer"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchFiltersByCountryIso2Code() async throws {
        let a1 = Actor(actorId: "id-1"); a1.countryIso2Code = "DE"
        let a2 = Actor(actorId: "id-2"); a2.countryIso2Code = "FR"
        try insert(a1, a2)

        let results = try await makeRepo().search(query: ActorQuery(countryIso2Code: "DE"))

        XCTAssertEqual(results.map(\.id), ["id-1"])
    }

    func testSearchReturnsEmptyWhenNoMatch() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Acme"
        try insert(a1)

        let results = try await makeRepo().search(query: ActorQuery(name: "Unknown"))

        XCTAssertTrue(results.isEmpty)
    }

    func testActorByIdReturnsMatchingActor() async throws {
        let a1 = Actor(actorId: "id-1"); a1.name = "Acme Medical GmbH"
        try insert(a1)

        let actor = try await makeRepo().actor(id: "id-1")

        XCTAssertEqual(actor?.id, "id-1")
        XCTAssertEqual(actor?.name, "Acme Medical GmbH")
    }

    func testActorByIdReturnsNilWhenNotFound() async throws {
        try insert(Actor(actorId: "id-1"))

        let actor = try await makeRepo().actor(id: "unknown")

        XCTAssertNil(actor)
    }
}

// MARK: - LocalUdiRepository

@MainActor
final class LocalUdiRepositoryTests: XCTestCase {

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

    private func insert(_ devices: UdiDevice...) throws {
        devices.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
    }

    private func makeRepo() -> LocalUdiDevicesRepository {
        LocalUdiDevicesRepository(modelContainer: container)
    }

    func testSearchReturnsAllWhenQueryIsEmpty() async throws {
        try insert(UdiDevice(primaryDi: "DI-001"), UdiDevice(primaryDi: "DI-002"))

        let results = try await makeRepo().search()

        XCTAssertEqual(results.count, 2)
    }

    func testSearchFiltersByPrimaryDi() async throws {
        try insert(UdiDevice(primaryDi: "DI-001"), UdiDevice(primaryDi: "DI-002"))

        let results = try await makeRepo().search(query: UdiDevicesQuery(primaryDi: "DI-001"))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchFiltersByTradeName() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.tradeName = "Acme Scanner Pro"
        let d2 = UdiDevice(primaryDi: "DI-002"); d2.tradeName = "Beta Probe"
        try insert(d1, d2)

        let results = try await makeRepo().search(query: UdiDevicesQuery(tradeName: "Acme Scanner Pro"))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchFiltersByMfSrn() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.mfSrn = "DE-MF-000012345"
        let d2 = UdiDevice(primaryDi: "DI-002"); d2.mfSrn = "FR-MF-000099999"
        try insert(d1, d2)

        let results = try await makeRepo().search(query: UdiDevicesQuery(mfSrn: "DE-MF-000012345"))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchFiltersByRiskClassId() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.riskClassId = 3
        let d2 = UdiDevice(primaryDi: "DI-002"); d2.riskClassId = 1
        try insert(d1, d2)

        let results = try await makeRepo().search(query: UdiDevicesQuery(riskClassId: 3))

        XCTAssertEqual(results.map(\.id), ["DI-001"])
    }

    func testSearchReturnsEmptyWhenNoMatch() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.tradeName = "Acme"
        try insert(d1)

        let results = try await makeRepo().search(query: UdiDevicesQuery(tradeName: "Unknown"))

        XCTAssertTrue(results.isEmpty)
    }

    func testDeviceByPrimaryDiReturnsMatchingDevice() async throws {
        let d1 = UdiDevice(primaryDi: "DI-001"); d1.tradeName = "Acme Scanner Pro"
        try insert(d1)

        let device = try await makeRepo().device(primaryDi: "DI-001")

        XCTAssertEqual(device?.id, "DI-001")
        XCTAssertEqual(device?.tradeName, "Acme Scanner Pro")
    }

    func testDeviceByPrimaryDiReturnsNilWhenNotFound() async throws {
        try insert(UdiDevice(primaryDi: "DI-001"))

        let device = try await makeRepo().device(primaryDi: "unknown")

        XCTAssertNil(device)
    }
}

// MARK: - LocalReferenceRepository

@MainActor
final class LocalReferenceRepositoryTests: XCTestCase {

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

    private func insert(_ entries: ReferenceEntry...) throws {
        entries.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
    }

    private func makeRepo() -> LocalReferenceRepository {
        LocalReferenceRepository(modelContainer: container)
    }

    func testSearchReturnsAllWhenQueryIsEmpty() async throws {
        try insert(ReferenceEntry(id: 1), ReferenceEntry(id: 2))

        let results = try await makeRepo().search()

        XCTAssertEqual(results.count, 2)
    }

    func testSearchFiltersByCode() async throws {
        let e1 = ReferenceEntry(id: 1); e1.code = "refdata.risk-class.class-iii"
        let e2 = ReferenceEntry(id: 2); e2.code = "refdata.risk-class.class-i"
        try insert(e1, e2)

        let results = try await makeRepo().search(query: ReferenceQuery(code: "refdata.risk-class.class-iii"))

        XCTAssertEqual(results.map(\.id), [1])
    }

    func testSearchFiltersByLanguage() async throws {
        let e1 = ReferenceEntry(id: 1); e1.language = "en"
        let e2 = ReferenceEntry(id: 2); e2.language = "de"
        try insert(e1, e2)

        let results = try await makeRepo().search(query: ReferenceQuery(language: "en"))

        XCTAssertEqual(results.map(\.id), [1])
    }

    func testSearchReturnsEmptyWhenNoMatch() async throws {
        let e1 = ReferenceEntry(id: 1); e1.code = "refdata.risk-class.class-iii"
        try insert(e1)

        let results = try await makeRepo().search(query: ReferenceQuery(code: "unknown"))

        XCTAssertTrue(results.isEmpty)
    }

    func testEntryByIdReturnsMatchingEntry() async throws {
        let e1 = ReferenceEntry(id: 42); e1.value = "Class III"
        try insert(e1)

        let entry = try await makeRepo().entry(id: 42)

        XCTAssertEqual(entry?.id, 42)
        XCTAssertEqual(entry?.value, "Class III")
    }

    func testEntryByIdReturnsNilWhenNotFound() async throws {
        try insert(ReferenceEntry(id: 1))

        let entry = try await makeRepo().entry(id: 999)

        XCTAssertNil(entry)
    }
}
