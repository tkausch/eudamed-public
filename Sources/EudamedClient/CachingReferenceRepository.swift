//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import os.log

private let logger = Logger(subsystem: "EudamedDataModel", category: "reference")

public actor CachingReferenceRepository: ReferenceRepository {

    private struct ReferenceKey: Hashable {
        let code: String
        let language: String
        let id: Int
    }

    private struct ReferenceGroup: Hashable {
        let code: String
        let language: String
    }

    // The values for each CodeID
    private var cache: [ReferenceKey: String] = [:]
    
    private var loadedGroups: Set<ReferenceGroup> = []

    private let remote: (any ReferenceRepository)?

    public init() {
        self.remote = try? RemoteReferenceRepository()
    }

    init(remote: any ReferenceRepository) {
        self.remote = remote
    }

    public func getReferenceValue(id: Int, code: String, language: String = "en") async -> String? {
        let key = ReferenceKey(code: code, language: language, id: id)
        if let value = cache[key] { return value }
        let group = ReferenceGroup(code: key.code, language: key.language)
        if !loadedGroups.contains(group) {
            _ = try? await fetchAndCache(group: group)
        }
        return cache[key]
    }

    public func search(query: ReferenceQuery = ReferenceQuery()) async throws -> [ReferenceEntry] {
        return (try? await remote?.search(query: query)) ?? []
    }

    private func fetchAndCache(group: ReferenceGroup) async throws  {
        let query = ReferenceQuery(code: group.code, language: group.language)
        guard let entries = try await remote?.search(query: query) else { return }
        for entry in entries {
            cache[ReferenceKey(code: entry.code, language: entry.language, id: entry.id)] = entry.value
            loadedGroups.insert(ReferenceGroup(code: entry.code, language: entry.language))
        }
        logger.debug("cache updated: \(entries.count) reference(s) added, \(self.loadedGroups.count) group(s) loaded")
    }

}
