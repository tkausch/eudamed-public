//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import SwiftData

public actor CachingActorRepository: ActorRepository {

    private let remote: RemoteActorRepository
    private let local: LocalActorRepository
    public private(set) var lastSync: Date?

    public init(modelContainer: ModelContainer) throws {
        self.remote = try RemoteActorRepository()
        self.local = LocalActorRepository(modelContainer: modelContainer)
    }

    init(modelContainer: ModelContainer, remote: RemoteActorRepository) {
        self.remote = remote
        self.local = LocalActorRepository(modelContainer: modelContainer)
    }

    public func search(query: ActorQuery = ActorQuery()) async throws -> [Actor] {
        try await local.search(query: query)
    }

    public func actor(id: String) async throws -> Actor? {
        try await local.actor(id: id)
    }

    public func sync() async throws {
        let actors = try await remote.search()
        try await local.upsert(actors)
        lastSync = .now
    }
}
