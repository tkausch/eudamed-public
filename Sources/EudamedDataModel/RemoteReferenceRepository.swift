//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedClient
import Foundation
import os.log

private let logger = Logger(subsystem: "EudamedDataModel", category: "reference")

public protocol ReferenceRepository: Sendable {
    func search(query: ReferenceQuery) async throws -> [ReferenceEntry]
    func entry(id: Int) async throws -> ReferenceEntry?
}

public struct ReferenceQuery: Sendable {
    public var id: Double?
    public var code: String?
    public var language: String?

    public init(
        id: Double? = nil,
        code: String? = nil,
        language: String? = nil
    ) {
        self.id = id
        self.code = code
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
                ID: query.id,
                CODE: query.code,
                LANGUAGE: query.language
            )
        )
        var result = [ReferenceEntry]()
        while true {
            let body = try await client.getReference(input).ok.body.json
            result += (body.value ?? []).compactMap { ReferenceEntry($0) }
            logger.info("getReference: fetched \(result.count) items so far")
            guard let cursor = body.nextLink.flatMap({ Self.extractAfterCursor(from: $0) }) else { break }
            input.query._dollar_after = cursor
        }
        return result
    }

    public func entry(id: Int) async throws -> ReferenceEntry? {
        try await search(query: ReferenceQuery(id: Double(id))).first
    }

    private static func extractAfterCursor(from nextLink: String) -> String? {
        URLComponents(string: nextLink)?.queryItems?.first(where: { $0.name == "$after" })?.value
    }
}
