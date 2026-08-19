//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedRest
import SwiftData

typealias RawReferenceEntry = Operations.getReference.Output.Ok.Body.jsonPayload.valuePayloadPayload

@Model
public final class ReferenceEntry: @unchecked Sendable, Identifiable, Hashable {
    /// Numeric identifier of the reference data entry.
    @Attribute(.unique) public var id: Int
    /// Machine-readable code of the reference data entry, e.g. "refdata.risk-class.class-iii".
    public var code: String?
    /// Language code of the localized value (e.g. en, fr, de).
    public var language: String?
    /// Human-readable, localized label for the reference data entry.
    public var value: String?

    public init(id: Int) {
        self.id = id
    }

    convenience init?(_ raw: RawReferenceEntry) {
        guard let id = raw.ID else { return nil }
        self.init(id: id)
        code     = raw.CODE
        language = raw.LANGUAGE
        value    = raw.VALUE
    }

    func update(from other: ReferenceEntry) {
        code     = other.code
        language = other.language
        value    = other.value
    }

    public func debugLog() -> String {
        "ReferenceEntry(id: \(id), code: \(code ?? "-"), language: \(language ?? "-"), value: \(value ?? "-"))"
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: ReferenceEntry, rhs: ReferenceEntry) -> Bool { lhs.id == rhs.id }
}
