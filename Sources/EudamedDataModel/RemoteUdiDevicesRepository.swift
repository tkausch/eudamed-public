//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import EudamedClient
import Foundation
import os.log

private let logger = Logger(subsystem: "EudamedDataModel", category: "udi")

public protocol UdiDevicesRepository: Sendable {
    func search(query: UdiDevicesQuery) async throws -> [UdiDevice]
    func device(primaryDi: String) async throws -> UdiDevice?
}

public struct UdiDevicesQuery: Sendable {
    public var primaryDi: String?
    public var basicUdi: String?
    public var tradeName: String?
    public var deviceName: String?
    public var deviceModel: String?
    public var reference: String?
    public var nomenclatureCode: String?
    public var riskClassId: Double?
    public var applicableLegislationId: Double?
    public var placedOnTheMarketId: Double?
    public var mfSrn: String?
    public var specialDeviceTypeId: Double?
    public var medicalPurpose: String?

    public init(
        primaryDi: String? = nil,
        basicUdi: String? = nil,
        tradeName: String? = nil,
        deviceName: String? = nil,
        deviceModel: String? = nil,
        reference: String? = nil,
        nomenclatureCode: String? = nil,
        riskClassId: Double? = nil,
        applicableLegislationId: Double? = nil,
        placedOnTheMarketId: Double? = nil,
        mfSrn: String? = nil,
        specialDeviceTypeId: Double? = nil,
        medicalPurpose: String? = nil
    ) {
        self.primaryDi = primaryDi
        self.basicUdi = basicUdi
        self.tradeName = tradeName
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.reference = reference
        self.nomenclatureCode = nomenclatureCode
        self.riskClassId = riskClassId
        self.applicableLegislationId = applicableLegislationId
        self.placedOnTheMarketId = placedOnTheMarketId
        self.mfSrn = mfSrn
        self.specialDeviceTypeId = specialDeviceTypeId
        self.medicalPurpose = medicalPurpose
    }
}

public struct RemoteUdiDevicesRepository: UdiDevicesRepository {

    private let client: any APIProtocol

    public init(client: any APIProtocol) {
        self.client = client
    }

    public init() throws {
        self.client = try Client()
    }

    public func search(query: UdiDevicesQuery = UdiDevicesQuery()) async throws -> [UdiDevice] {
        var input = Operations.getUdi.Input(
            query: .init(
                PRIMARY_DI: query.primaryDi,
                BASIC_UDI: query.basicUdi,
                TRADE_NAME: query.tradeName,
                DEVICE_NAME: query.deviceName,
                DEVICE_MODEL: query.deviceModel,
                REFERENCE: query.reference,
                NOMENCLATURE_CODE: query.nomenclatureCode,
                RISK_CLASS_ID: query.riskClassId,
                APPLICABLE_LEGISLATION_ID: query.applicableLegislationId,
                PLACED_ON_THE_MARKET_ID: query.placedOnTheMarketId,
                MF_SRN: query.mfSrn,
                SPECIAL_DEVICE_TYPE_ID: query.specialDeviceTypeId,
                MEDICAL_PURPOSE: query.medicalPurpose
            )
        )
        var result = [UdiDevice]()
        var page = 1
        while true {
            let body = try await client.getUdi(input).ok.body.json
            let pageDevices = (body.value ?? []).compactMap { UdiDevice($0) }
            result += pageDevices
            logger.info("getUdi: page \(page) — \(pageDevices.count) devices, \(result.count) total")
            guard let cursor = body.nextLink.flatMap({ Self.extractAfterCursor(from: $0) }) else { break }
            logger.info("getUdi: following nextLink to page \(page + 1) (cursor: \(cursor))")
            input.query._dollar_after = cursor
            page += 1
        }
        return result
    }

    public func device(primaryDi: String) async throws -> UdiDevice? {
        try await search(query: UdiDevicesQuery(primaryDi: primaryDi)).first
    }

    private static func extractAfterCursor(from nextLink: String) -> String? {
        URLComponents(string: nextLink)?.queryItems?.first(where: { $0.name == "$after" })?.value
    }
}
