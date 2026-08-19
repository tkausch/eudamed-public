//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedRest
import Foundation
import os.log



private let logger = Logger(subsystem: "EudamedDataModel", category: "pagination")

public protocol ActorRepository: Sendable {
    func search(query: ActorQuery) async throws -> [Actor]
    func actor(id: String) async throws -> Actor?
}

public struct ActorQuery: Sendable {
    public var actorId: String?
    public var name: String?
    public var abbreviatedName: String?
    public var actorType: String?
    public var countryIso2Code: String?

    public init(
        actorId: String? = nil,
        name: String? = nil,
        abbreviatedName: String? = nil,
        actorType: String? = nil,
        countryIso2Code: String? = nil
    ) {
        self.actorId = actorId
        self.name = name
        self.abbreviatedName = abbreviatedName
        self.actorType = actorType
        self.countryIso2Code = countryIso2Code
    }
}

public struct RemoteActorRepository: ActorRepository {

    private let client: any APIProtocol

    public init(client: any APIProtocol) {
        self.client = client
    }

    public init() throws {
        self.client = try Client()
    }

    public func search(query: ActorQuery = ActorQuery()) async throws -> [Actor] {
        var input = Operations.getActors.Input(
            query: .init(
                ACTOR_ID: query.actorId,
                NAME: query.name,
                ABBREVIATED_NAME: query.abbreviatedName,
                ACTOR_TYPE: query.actorType,
                ACT_COUNTRY_ISO2_CODE: query.countryIso2Code,
                format: "json",
                api_hyphen_version: "v1.0"
            )
        )
        var result = [Actor]()
        while true {
            let body = try await client.getActors(input).ok.body.json
            let pageActors = (body.value ?? []).compactMap { Actor($0) }
            pageActors.forEach { logger.debug("\($0.debugLog())") }
            result += pageActors
            logger.info("getActors: fetched \(result.count) items so far")
            guard let cursor = body.nextLink.flatMap({ Self.extractAfterCursor(from: $0) }) else { break }
            input.query._dollar_after = cursor
        }
        return result
    }

    public func actor(id: String) async throws -> Actor? {
        try await search(query: ActorQuery(actorId: id)).first
    }

    private static func extractAfterCursor(from nextLink: String) -> String? {
        URLComponents(string: nextLink)?.queryItems?.first(where: { $0.name == "$after" })?.value
    }
}
