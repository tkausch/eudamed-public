//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedRest
import SwiftData

typealias RawActor = Operations.getActors.Output.Ok.Body.jsonPayload.valuePayloadPayload

@Model
public final class Actor: @unchecked Sendable, Identifiable, Hashable {
    @Attribute(.unique) public var id: String
    public var actorId: String { id }
    public var name: String?
    public var abbreviatedName: String?
    public var status: String?
    public var statusFromDate: String?
    public var actorType: String?
    public var sponsorType: String?
    public var europeanVatNumber: String?
    public var version: Int?
    public var countryName: String?
    public var countryIso2Code: String?
    public var countryType: String?
    public var email: String?
    public var telephone: String?
    public var website: String?
    public var addressBuildingNumber: String?
    public var addressStreetName: String?
    public var addressPostBox: String?
    public var addressPostalZone: String?
    public var addressCityName: String?
    public var addressCountryName: String?
    public var addressCountryCode: String?
    public var addressCountryType: String?
    public var prrcFirstName: String?
    public var prrcFamilyName: String?

    public init(actorId: String) {
        self.id = actorId
    }

    convenience init?(_ raw: RawActor) {
        guard let id = raw.ACTOR_ID, !id.isEmpty else { return nil }
        self.init(actorId: id)
        name                  = raw.NAME
        abbreviatedName       = raw.ABBREVIATED_NAME
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

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: Actor, rhs: Actor) -> Bool { lhs.id == rhs.id }
}
