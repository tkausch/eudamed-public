//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedRest
import SwiftData

typealias RawUdiDevice = Operations.getUdi.Output.Ok.Body.jsonPayload.valuePayloadPayload

@Model
public final class UdiDevice: @unchecked Sendable, Identifiable, Hashable {
    /// Primary Device Identifier (UDI-DI).
    @Attribute(.unique) public var id: String
    public var primaryDi: String { id }

    /// Basic UDI-DI shared across all versions/packaging of this device model.
    public var basicUdi: String?
    /// Trade/brand name of the device.
    public var tradeName: String?
    /// Name of the device.
    public var deviceName: String?
    /// Model designation of the device.
    public var deviceModel: String?
    /// Manufacturer's reference/catalogue number for the device.
    public var reference: String?
    /// CND or GMDN nomenclature code assigned to the device.
    public var nomenclatureCode: String?
    /// Single Registration Number (SRN) of the manufacturer.
    public var mfSrn: String?
    /// Name of the manufacturer.
    public var mfName: String?
    /// Name(s) of the manufacturer actor.
    public var mfActorNames: String?
    /// Abbreviated name(s) of the associated actor(s).
    public var actorAbbreviatedNames: String?
    /// Classification rule/criterion applied to determine the device's risk class.
    public var deviceCriterion: String?
    /// Direct marking Device Identifier, if the device carries a direct UDI marking.
    public var directMarketingDi: String?

    /// Identifier of the device's risk class (see /reference; e.g. class I, IIa, IIb, III, or IVD classes A-D).
    public var riskClassId: Int?
    /// Identifier of the legislation the device is registered under (see /reference; e.g. MDD, MDR, IVDD, IVDR, AIMDD).
    public var applicableLegislationId: Int?
    /// Identifier of this record's status (see /reference).
    public var statusId: Int?
    /// Identifier of the device's market status (see /reference; e.g. on the market, no longer on the market, not intended for the EU market).
    public var deviceStatusTypeId: Int?
    /// Identifier of the country/market where the device is placed on the market.
    public var placedOnTheMarketId: Int?
    /// Version number of this UDI-DI record.
    public var versionNumber: Int?
    /// 1 if this is the latest version of the record, 0 otherwise.
    public var latestVersion: Int?

    /// 1 if the device is an active device, 0 otherwise.
    public var active: Int?
    /// 1 if the device is implantable, 0 otherwise.
    public var implantable: Int?
    /// 1 if the device is supplied sterile, 0 otherwise.
    public var sterile: Int?
    /// 1 if the device requires sterilization before use, 0 otherwise.
    public var sterilization: Int?
    /// 1 if the device is reusable, 0 otherwise.
    public var reusable: Int?
    /// 1 if the device is a reprocessed single-use device, 0 otherwise.
    public var reprocessed: Int?
    /// 1 if the device has a measuring function, 0 otherwise.
    public var measuringFunction: Int?
    /// 1 if the device administers or is used with a medicinal product, 0 otherwise.
    public var administeringMedicine: Int?
    /// 1 if the device incorporates or is derived from human tissues/cells, 0 otherwise.
    public var humanTissues: Int?
    /// 1 if the device incorporates or is derived from animal tissues/cells, 0 otherwise.
    public var animalTissues: Int?
    /// 1 if the device incorporates a human-derived product, 0 otherwise.
    public var humanProduct: Int?
    /// 1 if the device incorporates a medicinal product, 0 otherwise.
    public var medicinalProduct: Int?
    /// 1 if the device contains carcinogenic, mutagenic, or reprotoxic (CMR) substances, 0 otherwise.
    public var cmrSubstance: Int?
    /// 1 if the device contains endocrine-disrupting substances, 0 otherwise.
    public var endocrineDisruptor: Int?
    /// 1 if the device contains natural rubber latex, 0 otherwise.
    public var latex: Int?
    /// 1 if the device is a companion diagnostic, 0 otherwise (IVDs only).
    public var companionDiagnostics: Int?

    public init(primaryDi: String) {
        self.id = primaryDi
    }

    convenience init?(_ raw: RawUdiDevice) {
        guard let di = raw.PRIMARY_DI, !di.isEmpty else { return nil }
        self.init(primaryDi: di)
        basicUdi                = raw.BASIC_UDI
        tradeName               = raw.TRADE_NAME
        deviceName              = raw.DEVICE_NAME?.value as? String
        deviceModel             = raw.DEVICE_MODEL
        reference               = raw.REFERENCE
        nomenclatureCode        = raw.NOMENCLATURE_CODE
        mfSrn                   = raw.MF_SRN
        mfName                  = raw.MF_NAME
        mfActorNames            = raw.MF_ACTOR_NAMES
        actorAbbreviatedNames   = raw.ACTOR_ABBREVIATED_NAMES
        deviceCriterion         = raw.DEVICE_CRITERION
        directMarketingDi       = raw.DIRECT_MARKETING_DI
        riskClassId             = raw.RISK_CLASS_ID
        applicableLegislationId = raw.APPLICABLE_LEGISLATION_ID
        statusId                = raw.STATUS_ID
        deviceStatusTypeId      = raw.DEVICE_STATUS_TYPE_ID
        placedOnTheMarketId     = raw.PLACED_ON_THE_MARKET_ID
        versionNumber           = raw.VERSION_NUMBER
        latestVersion           = raw.LATEST_VERSION
        active                  = raw.ACTIVE
        implantable             = raw.IMPLANTABLE
        sterile                 = raw.STERILE
        sterilization           = raw.STERILIZATION
        reusable                = raw.REUSABLE
        reprocessed             = raw.REPROCESSED
        measuringFunction       = raw.MEASURING_FUNCTION
        administeringMedicine   = raw.ADMINISTERING_MEDICINE
        humanTissues            = raw.HUMAN_TISSUES
        animalTissues           = raw.ANIMAL_TISSUES
        humanProduct            = raw.HUMAN_PRODUCT
        medicinalProduct        = raw.MEDICINAL_PRODUCT
        cmrSubstance            = raw.CMR_SUBSTANCE
        endocrineDisruptor      = raw.ENDOCRINE_DISRUPTOR
        latex                   = raw.LATEX
        companionDiagnostics    = raw.COMPANION_DIAGNOSTICS?.value as? Int
    }

    func update(from other: UdiDevice) {
        basicUdi                = other.basicUdi
        tradeName               = other.tradeName
        deviceName              = other.deviceName
        deviceModel             = other.deviceModel
        reference               = other.reference
        nomenclatureCode        = other.nomenclatureCode
        mfSrn                   = other.mfSrn
        mfName                  = other.mfName
        mfActorNames            = other.mfActorNames
        actorAbbreviatedNames   = other.actorAbbreviatedNames
        deviceCriterion         = other.deviceCriterion
        directMarketingDi       = other.directMarketingDi
        riskClassId             = other.riskClassId
        applicableLegislationId = other.applicableLegislationId
        statusId                = other.statusId
        deviceStatusTypeId      = other.deviceStatusTypeId
        placedOnTheMarketId     = other.placedOnTheMarketId
        versionNumber           = other.versionNumber
        latestVersion           = other.latestVersion
        active                  = other.active
        implantable             = other.implantable
        sterile                 = other.sterile
        sterilization           = other.sterilization
        reusable                = other.reusable
        reprocessed             = other.reprocessed
        measuringFunction       = other.measuringFunction
        administeringMedicine   = other.administeringMedicine
        humanTissues            = other.humanTissues
        animalTissues           = other.animalTissues
        humanProduct            = other.humanProduct
        medicinalProduct        = other.medicinalProduct
        cmrSubstance            = other.cmrSubstance
        endocrineDisruptor      = other.endocrineDisruptor
        latex                   = other.latex
        companionDiagnostics    = other.companionDiagnostics
    }

    public func debugLog() -> String {
        "UdiDevice(primaryDi: \(id), tradeName: \(tradeName ?? "-"), deviceName: \(deviceName ?? "-"), mfName: \(mfName ?? "-"), statusId: \(statusId.map(String.init) ?? "-"))"
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: UdiDevice, rhs: UdiDevice) -> Bool { lhs.id == rhs.id }
}
