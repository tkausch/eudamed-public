//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedClient
import SwiftData

typealias RawUdiDevice = Operations.getUdi.Output.Ok.Body.jsonPayload.valuePayloadPayload

@Model
public final class UdiDevice: @unchecked Sendable, Identifiable, Hashable {
    @Attribute(.unique) public var id: String
    public var primaryDi: String { id }

    public var basicUdi: String?
    public var tradeName: String?
    public var deviceName: String?
    public var deviceModel: String?
    public var reference: String?
    public var nomenclatureCode: String?
    public var mfSrn: String?
    public var mfName: String?
    public var mfActorNames: String?
    public var actorAbbreviatedNames: String?
    public var deviceCriterion: String?
    public var directMarketingDi: String?

    public var riskClassId: Int?
    public var applicableLegislationId: Int?
    public var statusId: Int?
    public var deviceStatusTypeId: Int?
    public var placedOnTheMarketId: Int?
    public var versionNumber: Int?
    public var latestVersion: Int?

    public var active: Int?
    public var implantable: Int?
    public var sterile: Int?
    public var sterilization: Int?
    public var reusable: Int?
    public var reprocessed: Int?
    public var measuringFunction: Int?
    public var administeringMedicine: Int?
    public var humanTissues: Int?
    public var animalTissues: Int?
    public var humanProduct: Int?
    public var medicinalProduct: Int?
    public var cmrSubstance: Int?
    public var endocrineDisruptor: Int?
    public var latex: Int?
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

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: UdiDevice, rhs: UdiDevice) -> Bool { lhs.id == rhs.id }
}
