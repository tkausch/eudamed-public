//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import SwiftData

public actor CachingReferenceRepository: ReferenceRepository {

    private let remote: RemoteReferenceRepository
    private let local: LocalReferenceRepository
    public private(set) var lastSync: Date?

    public init(modelContainer: ModelContainer) throws {
        self.remote = try RemoteReferenceRepository()
        self.local = LocalReferenceRepository(modelContainer: modelContainer)
    }

    init(modelContainer: ModelContainer, remote: RemoteReferenceRepository) {
        self.remote = remote
        self.local = LocalReferenceRepository(modelContainer: modelContainer)
    }

    public func search(query: ReferenceQuery = ReferenceQuery()) async throws -> [ReferenceEntry] {
        try await local.search(query: query)
    }

    public func entry(id: Int) async throws -> ReferenceEntry? {
        try await local.entry(id: id)
    }

    public func cacheCount() async throws -> Int {
        return try await local.search().count
    }
    
    public func sync() async throws {
        let entries = try await remote.search()
        try await local.upsert(entries)
        lastSync = .now
    }
}
