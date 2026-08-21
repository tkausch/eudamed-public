//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import XCTest
@testable import EudamedClient

// MARK: - Mocks

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

private actor ThrowingMockReferenceRepository: ReferenceRepository {
    private(set) var callCount = 0

    func search(query: ReferenceQuery) async throws -> [ReferenceEntry] {
        callCount += 1
        throw URLError(.notConnectedToInternet)
    }

    func getReferenceValue(id: Int, code: String, language: String) async -> String? { nil }
}

// MARK: - Tests

final class CachingReferenceRepositoryTests: XCTestCase {

    private func makeEntries() -> [ReferenceEntry] {
        var e1 = ReferenceEntry(id: 1)
        e1.code = "RISK_CLASS_ID"
        e1.language = "en"
        e1.value = "Class I"

        var e2 = ReferenceEntry(id: 2)
        e2.code = "RISK_CLASS_ID"
        e2.language = "en"
        e2.value = "Class III"

        var e3 = ReferenceEntry(id: 3)
        e3.code = "RISK_CLASS_ID"
        e3.language = "de"
        e3.value = "Klasse I"

        return [e1, e2, e3]
    }

    // MARK: Remote call behavior (search is never cached)

    func testHitsRemoteWhenGroupNotCached() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search(query: ReferenceQuery(code: "RISK_CLASS_ID", language: "en"))

        let count = await mock.callCount
        XCTAssertEqual(count, 1)
    }

    func testSearchAlwaysHitsRemote() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search(query: ReferenceQuery(code: "RISK_CLASS_ID", language: "en"))
        _ = try await repo.search(query: ReferenceQuery(code: "RISK_CLASS_ID", language: "en"))

        let count = await mock.callCount
        XCTAssertEqual(count, 2)
    }

    func testUnfilteredSearchAlwaysHitsRemote() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = try await repo.search()
        _ = try await repo.search()

        let count = await mock.callCount
        XCTAssertEqual(count, 2)
    }

    // MARK: getReferenceValue – cache hits

    func testGetReferenceValueFetchesGroupOnFirstCall() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        let value = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")

        XCTAssertEqual(value, "Class I")
        let count = await mock.callCount
        XCTAssertEqual(count, 1)
    }

    func testGetReferenceValueServedFromCacheAfterFirstFetch() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")   // fetch group
        _ = await repo.getReferenceValue(id: 2, code: "RISK_CLASS_ID", language: "en")   // same group, from cache

        let count = await mock.callCount
        XCTAssertEqual(count, 1)
    }

    func testGetReferenceValueReturnsNilForUnknownIdWithoutRefetch() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")   // fetch group
        let value = await repo.getReferenceValue(id: 999, code: "RISK_CLASS_ID", language: "en")  // unknown id

        XCTAssertNil(value)
        let count = await mock.callCount
        XCTAssertEqual(count, 1)  // group already cached, no second remote call
    }

    // MARK: getReferenceValue – group isolation

    func testGetReferenceValueDifferentCodeFetchesNewGroup() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")  // fetch RISK_CLASS_ID/en group
        _ = await repo.getReferenceValue(id: 1, code: "DEVICE_TYPE", language: "en")    // different code → new fetch

        let count = await mock.callCount
        XCTAssertEqual(count, 2)
    }

    func testGetReferenceValueSideEffectCachesOtherLanguageGroups() async throws {
        // The mock returns all entries regardless of query, so a fetch for "en" also
        // delivers the "de" entry. That "de" group should be marked as loaded too.
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        _ = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")  // fetches; response includes de entry
        let value = await repo.getReferenceValue(id: 3, code: "RISK_CLASS_ID", language: "de")  // served from cache

        XCTAssertEqual(value, "Klasse I")
        let count = await mock.callCount
        XCTAssertEqual(count, 1)
    }

    // MARK: getReferenceValue – empty remote response

    func testGetReferenceValueReturnsNilWhenRemoteIsEmpty() async throws {
        let mock = MockReferenceRepository(entries: [])
        let repo = CachingReferenceRepository(remote: mock)

        let value = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")

        XCTAssertNil(value)
    }

    func testGetReferenceValueRetriesWhenPreviousResponseWasEmpty() async throws {
        // Empty responses do not insert the group into loadedGroups, so the next
        // call for the same group must hit the remote again.
        let mock = MockReferenceRepository(entries: [])
        let repo = CachingReferenceRepository(remote: mock)

        _ = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")  // empty response
        _ = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")  // retries

        let count = await mock.callCount
        XCTAssertEqual(count, 2)
    }

    // MARK: getReferenceValue – remote errors

    func testGetReferenceValueReturnsNilWhenRemoteThrows() async {
        let mock = ThrowingMockReferenceRepository()
        let repo = CachingReferenceRepository(remote: mock)

        let value = await repo.getReferenceValue(id: 1, code: "RISK_CLASS_ID", language: "en")

        XCTAssertNil(value)
    }

    func testSearchReturnsEmptyArrayWhenRemoteThrows() async throws {
        let mock = ThrowingMockReferenceRepository()
        let repo = CachingReferenceRepository(remote: mock)

        let results = try await repo.search(query: ReferenceQuery(code: "RISK_CLASS_ID", language: "en"))

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: First-fetch result

    func testFirstSearchReturnsRemoteResults() async throws {
        let mock = MockReferenceRepository(entries: makeEntries())
        let repo = CachingReferenceRepository(remote: mock)

        let results = try await repo.search(query: ReferenceQuery(code: "RISK_CLASS_ID", language: "en"))

        XCTAssertEqual(results.count, 3)
    }
}
