//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import os.log

private let logger = Logger(subsystem: "EudamedDataModel", category: "reference")

public actor CachingReferenceRepository: ReferenceRepository {

    private var cachedEntries = [ReferenceEntry]()

    private let remote: (any ReferenceRepository)?


    public init() {
        self.remote = try? RemoteReferenceRepository()
    }

    init(remote: any ReferenceRepository) {
        self.remote = remote
    }

    public func search(query: ReferenceQuery = ReferenceQuery()) async throws -> [ReferenceEntry] {
        let cached = await searchFromCache(query: query)
        guard cached.isEmpty else {
            logger.debug("cache hit: returning \(cached.count) reference(s) from cache")
            return cached
        }
        return try await loadFromRemoteAndCache(query: query)
    }

    public func getReferenceValue(id: Double, code: String, language: String = "en") async -> String? {
        let query = ReferenceQuery(id: Int(id), code: code, language: language)
        return try? await search(query: query).first?.value
    }


    private func searchFromCache(query: ReferenceQuery) async -> [ReferenceEntry] {
        cachedEntries.filter { entry in
            if query.id != 0, query.id != entry.id { return false }
            if !query.code.isEmpty, query.code != entry.code { return false }
            if !query.language.isEmpty, query.language != entry.language { return false }
            return true
        }
    }

    private func loadFromRemoteAndCache(query: ReferenceQuery) async throws -> [ReferenceEntry] {
        guard let newReferences = try await remote?.search(query: query) else { return [] }
        cachedEntries += newReferences
        return newReferences
    }

}
