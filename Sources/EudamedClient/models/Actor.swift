//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedRest
import SwiftData

typealias RawActor = Operations.getActors.Output.Ok.Body.jsonPayload.valuePayloadPayload

extension String {
    var strippingQuotes: String {
        let quotes: Set<Character> = ["\"", "'", "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}"]
        var s = self
        while let first = s.first, quotes.contains(first) { s.removeFirst() }
        while let last = s.last, quotes.contains(last) { s.removeLast() }
        return s
    }
}

@Model
public final class Actor: @unchecked Sendable, Identifiable, Hashable {
    /// Unique EUDAMED identifier (UUID) of the actor.
    @Attribute(.unique) public var id: String
    public var actorId: String { id }
    /// Full registered name of the actor.
    public var name: String?
    /// Abbreviated/short name of the actor.
    public var abbreviatedName: String?
    /// Current status of the actor's registration, e.g. active.
    public var status: String?
    /// Date from which the current status has applied.
    public var statusFromDate: String?
    /// Type of actor, e.g. manufacturer, authorised representative, or importer.
    public var actorType: String?
    /// Type of clinical investigation sponsor, if the actor is registered as one.
    public var sponsorType: String?
    /// European VAT number of the actor, if applicable.
    public var europeanVatNumber: String?
    /// Version number of this actor record.
    public var version: Int?
    /// Name of the country associated with the actor.
    public var countryName: String?
    /// ISO 3166-1 alpha-2 code of the actor's country.
    public var countryIso2Code: String?
    /// Indicates whether the actor's country is an EU member state or a non-EU country.
    public var countryType: String?
    /// Contact email address of the actor.
    public var email: String?
    /// Contact telephone number of the actor.
    public var telephone: String?
    /// Website URL of the actor.
    public var website: String?
    /// Building/house number of the actor's registered address.
    public var addressBuildingNumber: String?
    /// Street name of the actor's registered address.
    public var addressStreetName: String?
    /// Post box of the actor's registered address, if used instead of a street address.
    public var addressPostBox: String?
    /// Postal/ZIP code of the actor's registered address.
    public var addressPostalZone: String?
    /// City of the actor's registered address.
    public var addressCityName: String?
    /// Country name of the actor's registered address.
    public var addressCountryName: String?
    /// ISO 3166-1 alpha-2 code of the actor's registered address country.
    public var addressCountryCode: String?
    /// Indicates whether the address country is an EU member state or a non-EU country.
    public var addressCountryType: String?
    /// First name of the actor's Person Responsible for Regulatory Compliance (PRRC).
    public var prrcFirstName: String?
    /// Family name of the actor's Person Responsible for Regulatory Compliance (PRRC).
    public var prrcFamilyName: String?

    public init(actorId: String) {
        self.id = actorId
    }

    convenience init?(_ raw: RawActor) {
        guard let id = raw.ACTOR_ID, !id.isEmpty else { return nil }
        self.init(actorId: id)
        name                  = raw.NAME?.strippingQuotes
        abbreviatedName       = raw.ABBREVIATED_NAME?.strippingQuotes
        status                = raw.STATUS
        statusFromDate        = raw.STATUS_FROM_DATE?.value as? String
        actorType             = raw.ACTOR_TYPE
        sponsorType           = raw.SPONSOR_TYPE?.value as? String
        europeanVatNumber     = raw.EUROPEAN_VAT_NUMBER
        version               = raw.VERSION
        countryName           = raw.ACT_COUNTRY_NAME
        countryIso2Code       = raw.ACT_COUNTRY_ISO2_CODE
        countryType           = raw.ACT_COUNTRY_TYPE
        email                 = raw.ACT_EMAIL
        telephone             = raw.ACT_TELEPHONE
        website               = raw.ACT_WEBSITE
        addressBuildingNumber = raw.ACT_ADDR_BUILDING_NUMBER
        addressStreetName     = raw.ACT_ADDR_STREET_NAME
        addressPostBox        = raw.ACT_ADDR_POST_BOX?.value as? String
        addressPostalZone     = raw.ACT_ADDR_POSTAL_ZONE
        addressCityName       = raw.ACT_ADDR_CITY_NAME
        addressCountryName    = raw.ACT_ADDR_COUNTRY_NAME
        addressCountryCode    = raw.ACT_ADDR_COUNTRY_CODE
        addressCountryType    = raw.ACT_ADDR_COUNTRY_TYPE
        prrcFirstName         = raw.PRRC_FIRST_NAME
        prrcFamilyName        = raw.PRRC_FAMILY_NAME
    }

    func update(from other: Actor) {
        name                  = other.name
        abbreviatedName       = other.abbreviatedName
        status                = other.status
        statusFromDate        = other.statusFromDate
        actorType             = other.actorType
        sponsorType           = other.sponsorType
        europeanVatNumber     = other.europeanVatNumber
        version               = other.version
        countryName           = other.countryName
        countryIso2Code       = other.countryIso2Code
        countryType           = other.countryType
        email                 = other.email
        telephone             = other.telephone
        website               = other.website
        addressBuildingNumber = other.addressBuildingNumber
        addressStreetName     = other.addressStreetName
        addressPostBox        = other.addressPostBox
        addressPostalZone     = other.addressPostalZone
        addressCityName       = other.addressCityName
        addressCountryName    = other.addressCountryName
        addressCountryCode    = other.addressCountryCode
        addressCountryType    = other.addressCountryType
        prrcFirstName         = other.prrcFirstName
        prrcFamilyName        = other.prrcFamilyName
    }

    public func debugLog() -> String {
        "Actor(id: \(id), name: \(name ?? "-"), abbreviatedName: \(abbreviatedName ?? "-"), status: \(status ?? "-"), actorType: \(actorType ?? "-"), country: \(countryIso2Code ?? "-"))"
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: Actor, rhs: Actor) -> Bool { lhs.id == rhs.id }
}
