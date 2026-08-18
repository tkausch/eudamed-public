//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import XCTest
import SwiftData
@testable import EudamedDataModel

// Live tests — require network access to the EUDAMED public API.
// Skip these in CI by setting the SKIP_LIVE_TESTS environment variable.

final class CachingUdiRepositoryLiveTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["ENABLE_LIVE_TESTS"] == nil,
            "Live tests disabled"
        )
        container = try ModelContainer(
            for: UdiDevice.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() async throws {
        container = nil
    }

    func testSyncPersistsLiveDevicesAndSearchQueriesLocally() async throws {
        let repo = try CachingUdiRepository(modelContainer: container)

        try await repo.sync()

        let lastSync = await repo.lastSync
        XCTAssertNotNil(lastSync)
        let results = try await repo.search()
        XCTAssertFalse(results.isEmpty, "Expected devices from EUDAMED after sync")
    }
}
