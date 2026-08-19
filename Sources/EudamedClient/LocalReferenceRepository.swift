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
        guard !entries.isEmpty else { return }

        var incomingByID: [Int: ReferenceEntry] = [:]
        for entry in entries { incomingByID[entry.id] = entry }

        let ids = Array(incomingByID.keys)
        let existing = try modelContext.fetch(
            FetchDescriptor<ReferenceEntry>(predicate: #Predicate { ids.contains($0.id) })
        )
        let existingByID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for (_, incoming) in incomingByID {
            if let existing = existingByID[incoming.id] {
                existing.update(from: incoming)
            } else {
                let newEntry = ReferenceEntry(id: incoming.id)
                modelContext.insert(newEntry)
                newEntry.update(from: incoming)
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
