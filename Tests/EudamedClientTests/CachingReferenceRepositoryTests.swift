//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import XCTest
@testable import EudamedClient

// MARK: - Mock

private actor MockReferenceRepository: ReferenceRepository {
    private(set) var callCount = 0
    let entries: [ReferenceEntry]

    init(entries: [ReferenceEntry] = []) {
        self.entries = entries
    }

    func search(query: ReferenceQuery) async throws -> [ReferenceEntry] {
        callCount += 1
        return entries
    }

    func getReferenceValue(id: Int, code: String, language: String) async -> String? {
        entries.first { $0.code == code && $0.language == language }?.value
    }
}

// MARK: - Tests

final class CachingReferenceRepositoryTests: XCTestCase {

    private func makeEntries() -> [ReferenceEntry] {
        var e1 = ReferenceEntry(id: 1)
        e1.code = "refdata.risk-class.class-i"
        e1.language = "en"
        e1.value = "Class I"

        var e2 = ReferenceEntry(id: 2)
        e2.code = "refdata.risk-class.class-iii"
        e2.language = "en"
        e2.value = "Class III"

        var e3 = ReferenceEntry(id: 3)
        e3.code = "refdata.risk-class.class-i"
        e3.language = "de"
        e3.value = "Klasse I"

        return [e1, e2, e3]
    }

    // MARK: Remote call behavior

    func testHitsRemoteWhenCacheIsEmpty() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()

        let count = await mock.callCount
        XCTAssertEqual(count, 1)
    }

    func testDoesNotHitRemoteWhenCacheHasMatchingEntries() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()     // prime cache
        _ = try await repo.search()     // served from cache

        let count = await mock.callCount
        XCTAssertEqual(count, 1)
    }

    func testCachedEntriesServeMultipleDifferentFilteredQueries() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()     // prime cache with all entries
        _ = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-i"))
        _ = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-iii"))

        let count = await mock.callCount
        XCTAssertEqual(count, 1)
    }

    // MARK: Filter behavior

    func testUnfilteredSearchReturnsAllCachedEntries() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()     // prime cache
        let results = try await repo.search()

        XCTAssertEqual(results.count, 3)
    }

    func testFiltersByCode() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()     // prime cache
        let results = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-i"))

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.code == "refdata.risk-class.class-i" })
    }

    func testFiltersByLanguage() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()     // prime cache
        let results = try await repo.search(query: ReferenceQuery(language: "de"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, 3)
    }

    func testFiltersByCodeAndLanguage() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()     // prime cache
        let results = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-i", language: "en"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, 1)
    }

    // MARK: First-fetch result

    func testFirstSearchReturnsRemoteResults() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        let results = try await repo.search()

        XCTAssertEqual(results.count, 3)
    }
}
