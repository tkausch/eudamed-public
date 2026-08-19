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
        guard !actors.isEmpty else { return }

        // Deduplicate by id — remote pagination can yield the same actor more than once.
        // Inserting two @Model objects with the same unique id in one save causes a fatal
        // "remapped to temporary identifier" error in SwiftData's DefaultStore.
        var incomingByID: [String: Actor] = [:]
        for actor in actors { incomingByID[actor.id] = actor }

        let ids = Array(incomingByID.keys)
        let existing = try modelContext.fetch(
            FetchDescriptor<Actor>(predicate: #Predicate { ids.contains($0.id) })
        )
        let existingByID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for (_, incoming) in incomingByID {
            if let existing = existingByID[incoming.id] {
                existing.update(from: incoming)
            } else {
                // Create a fresh instance owned by this context rather than inserting the
                // remote-sourced @Model object directly. Inserting a @Model instance that
                // was created outside this ModelContext causes SwiftData to fail to remap
                // its temporary PersistentIdentifier to a permanent one during save.
                let newActor = Actor(actorId: incoming.id)
                modelContext.insert(newActor)
                newActor.update(from: incoming)
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
