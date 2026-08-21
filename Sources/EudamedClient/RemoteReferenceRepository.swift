//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedRest
import Foundation
import os.log

private let logger = Logger(subsystem: "EudamedDataModel", category: "reference")

public protocol ReferenceRepository: Sendable {
    func search(query: ReferenceQuery) async throws -> [ReferenceEntry]
    func getReferenceValue(id: Int, code: String, language: String) async -> String?
}

public struct ReferenceQuery: Sendable {
    public var id: Int?
    public var code: String?
    public var language: String?

    public init(
        id: Int? = nil,
        code: String? = nil,
        language: String? = nil
    ) {
        self.id = id
        self.code = code?.capitalized
        self.language = language
    }
}

public struct RemoteReferenceRepository: ReferenceRepository {

    private let client: any APIProtocol

    public init(client: any APIProtocol) {
        self.client = client
    }

    public init() throws {
        self.client = try Client()
    }

    public func search(query: ReferenceQuery = ReferenceQuery()) async throws -> [ReferenceEntry] {
        var input = Operations.getReference.Input(
            query: .init(
                ID: query.id.map { Double($0) },
                CODE: query.code,
                LANGUAGE: query.language
            )
        )
        var result = [ReferenceEntry]()
        while true {
            let body = try await client.getReference(input).ok.body.json
            let pageEntries = (body.value ?? []).compactMap { ReferenceEntry($0) }
            pageEntries.forEach { logger.debug("\($0.debugLog())") }
            result += pageEntries
            guard let cursor = body.nextLink.flatMap({ Self.extractAfterCursor(from: $0) }) else { break }
            input.query._dollar_after = cursor
        }
        return result
    }

    public func getReferenceValue(id: Int, code: String, language: String) async -> String? {
        let query = ReferenceQuery(id: id, code: code, language: language)
        return try? await search(query: query).first?.value
    }

    private static func extractAfterCursor(from nextLink: String) -> String? {
        URLComponents(string: nextLink)?.queryItems?.first(where: { $0.name == "$after" })?.value
    }
}
