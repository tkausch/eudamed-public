//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import SwiftData

// MARK: - LocalReferenceRepository

@ModelActor
public actor LocalReferenceRepository: ReferenceRepository {

    public func search(query: ReferenceQuery = ReferenceQuery()) async throws -> [ReferenceEntry] {
        let predicate = buildPredicate(query: query)
        return try modelContext.fetch(FetchDescriptor<ReferenceEntry>(predicate: predicate))
    }

    public func entry(id: Int) async throws -> ReferenceEntry? {
        try await search(query: ReferenceQuery(id: Double(id))).first
    }

    public func upsert(_ entries: [ReferenceEntry]) throws {
        for incoming in entries {
            let id = incoming.id
            let predicate = #Predicate<ReferenceEntry> { $0.id == id }
            if let existing = try modelContext.fetch(FetchDescriptor<ReferenceEntry>(predicate: predicate)).first {
                existing.update(from: incoming)
            } else {
                modelContext.insert(incoming)
            }
        }
        try modelContext.save()
    }

    private func buildPredicate(query: ReferenceQuery) -> Predicate<ReferenceEntry> {
        let id = query.id.map { Int($0) } ?? 0
        let ignoreId = query.id == nil
        let code = query.code ?? ""
        let ignoreCode = query.code == nil
        let language = query.language ?? ""
        let ignoreLanguage = query.language == nil

        return #Predicate<ReferenceEntry> { r in
            (ignoreId || r.id == id) &&
            (ignoreCode || r.code == code) &&
            (ignoreLanguage || r.language == language)
        }
    }
}
