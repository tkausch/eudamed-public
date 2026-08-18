//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import SwiftData


// MARK: - LocalActorRepository

@ModelActor
public actor LocalActorRepository: ActorRepository {

    public func search(query: ActorQuery = ActorQuery()) async throws -> [Actor] {
        let predicate = buildPredicate(query: query)
        return try modelContext.fetch(FetchDescriptor<Actor>(predicate: predicate))
    }

    public func actor(id: String) async throws -> Actor? {
        try await search(query: ActorQuery(actorId: id)).first
    }

    public func upsert(_ actors: [Actor]) throws {
        for incoming in actors {
            let id = incoming.id
            let predicate = #Predicate<Actor> { $0.id == id }
            if let existing = try modelContext.fetch(FetchDescriptor<Actor>(predicate: predicate)).first {
                existing.update(from: incoming)
            } else {
                modelContext.insert(incoming)
            }
        }
        try modelContext.save()
    }

    private func buildPredicate(query: ActorQuery) -> Predicate<Actor> {
        let actorId = query.actorId ?? ""
        let ignoreActorId = query.actorId == nil
        let name = query.name ?? ""
        let ignoreName = query.name == nil
        let abbreviatedName = query.abbreviatedName ?? ""
        let ignoreAbbreviatedName = query.abbreviatedName == nil
        let actorType = query.actorType ?? ""
        let ignoreActorType = query.actorType == nil
        let countryIso2Code = query.countryIso2Code ?? ""
        let ignoreCountryIso2Code = query.countryIso2Code == nil

        return #Predicate<Actor> { a in
            (ignoreActorId || a.id == actorId) &&
            (ignoreName || a.name == name) &&
            (ignoreAbbreviatedName || a.abbreviatedName == abbreviatedName) &&
            (ignoreActorType || a.actorType == actorType) &&
            (ignoreCountryIso2Code || a.countryIso2Code == countryIso2Code)
        }
    }

}
