import XCTest
import SwiftData
@testable import EudamedClient

@MainActor
final class LocalReferenceRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repo: LocalReferenceRepository!

    override func setUp() async throws {
        container = try ModelContainer(
            for: ReferenceEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repo = LocalReferenceRepository(modelContainer: container)
    }

    override func tearDown() async throws {
        repo = nil
        container = nil
    }

    private func insert(_ entries: ReferenceEntry...) throws {
        entries.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
    }

    func testSearchReturnsAllWhenQueryIsEmpty() async throws {
        try insert(ReferenceEntry(id: 1), ReferenceEntry(id: 2))

        let results = try await repo.search()

        XCTAssertEqual(results.count, 2)
    }

    func testSearchFiltersByCode() async throws {
        let e1 = ReferenceEntry(id: 1); e1.code = "refdata.risk-class.class-iii"
        let e2 = ReferenceEntry(id: 2); e2.code = "refdata.risk-class.class-i"
        try insert(e1, e2)

        let results = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-iii"))

        XCTAssertEqual(results.map(\.id), [1])
    }

    func testSearchFiltersByLanguage() async throws {
        let e1 = ReferenceEntry(id: 1); e1.language = "en"
        let e2 = ReferenceEntry(id: 2); e2.language = "de"
        try insert(e1, e2)

        let results = try await repo.search(query: ReferenceQuery(language: "en"))

        XCTAssertEqual(results.map(\.id), [1])
    }

    func testSearchReturnsEmptyWhenNoMatch() async throws {
        let e1 = ReferenceEntry(id: 1); e1.code = "refdata.risk-class.class-iii"
        try insert(e1)

        let results = try await repo.search(query: ReferenceQuery(code: "unknown"))

        XCTAssertTrue(results.isEmpty)
    }

    func testEntryByIdReturnsMatchingEntry() async throws {
        let e1 = ReferenceEntry(id: 42); e1.value = "Class III"
        try insert(e1)

        let entry = try await repo.entry(id: 42)

        XCTAssertEqual(entry?.id, 42)
        XCTAssertEqual(entry?.value, "Class III")
    }

    func testEntryByIdReturnsNilWhenNotFound() async throws {
        try insert(ReferenceEntry(id: 1))

        let entry = try await repo.entry(id: 999)

        XCTAssertNil(entry)
    }
}
