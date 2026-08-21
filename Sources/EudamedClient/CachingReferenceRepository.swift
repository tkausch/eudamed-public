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
        let result = try await loadFromRemoteAndCache(query: query)
        return result
    }

    public func getReferenceValue(id: Int, code: String, language: String = "en") async -> String? {
        // Query by code+language only so all entries for that reference list are cached together.
        // Filter by id locally to avoid a separate remote call per unique id.
        let query = ReferenceQuery(code: code, language: language)
        let entries = try? await search(query: query)
        return entries?.first { $0.id == id }?.value
    }


    private func searchFromCache(query: ReferenceQuery) async -> [ReferenceEntry] {
        cachedEntries.filter { entry in
            if let id = query.id, id != entry.id { return false }
            if let code = query.code, code != entry.code { return false }
            if let language = query.language, language != entry.language { return false }
            return true
        }
    }

    private func loadFromRemoteAndCache(query: ReferenceQuery) async throws -> [ReferenceEntry] {
        guard let newReferences = try await remote?.search(query: query) else { return [] }
        cachedEntries += newReferences
        if logger.isEnabled(type: .debug) {
            logger.debug("cache updated: \(newReferences.count) new reference(s) added, total \(self.cachedEntries.count) cached")
            for entry in newReferences {
                logger.debug("  cached reference: id=\(entry.id) code=\(entry.code) language=\(entry.language) value=\(entry.value)")
            }
        }
        return newReferences
    }

}
