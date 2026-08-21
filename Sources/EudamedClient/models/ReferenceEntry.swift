//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedRest

typealias RawReferenceEntry = Operations.getReference.Output.Ok.Body.jsonPayload.valuePayloadPayload

public struct ReferenceEntry: @unchecked Sendable, Identifiable, Hashable {
    /// Numeric identifier of the reference data entry.
    public var id: Int
    /// Machine-readable code of the reference data entry, e.g. "refdata.risk-class.class-iii".
    public var code: String
    /// Language code of the localized value (e.g. en, fr, de).
    public var language: String
    /// Human-readable, localized label for the reference data entry.
    public var value: String

    public init(id: Int, code: String = "", language: String = "", value: String = "") {
        self.id = id
        self.code = code
        self.language = language
        self.value = value
    }

    init?(_ raw: RawReferenceEntry) {
        guard let id = raw.ID else { return nil }
        self.id = id
        self.code = raw.CODE ?? ""
        self.language = raw.LANGUAGE ?? ""
        self.value = raw.VALUE ?? ""
    }

    public func debugLog() -> String {
        "ReferenceEntry(id: \(id), code: \(code), language: \(language), value: \(value))"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(code)
        hasher.combine(language)
        hasher.combine(value)
    }

    public static func == (lhs: ReferenceEntry, rhs: ReferenceEntry) -> Bool {
        lhs.id == rhs.id && lhs.code == rhs.code && lhs.language == rhs.language && lhs.value == rhs.value
    }
}
