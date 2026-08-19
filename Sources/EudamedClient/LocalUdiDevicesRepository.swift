//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import SwiftData

// MARK: - LocalUdiRepository

@ModelActor
public actor LocalUdiDevicesRepository: UdiDevicesRepository {

    public func search(query: UdiDevicesQuery = UdiDevicesQuery()) async throws -> [UdiDevice] {
        let candidates = try modelContext.fetch(
            FetchDescriptor<UdiDevice>(predicate: buildIdentifierPredicate(query: query))
        )
        let classification = buildClassificationPredicate(query: query)
        return try candidates.filter { try classification.evaluate($0) }
    }

    public func device(primaryDi: String) async throws -> UdiDevice? {
        try await search(query: UdiDevicesQuery(primaryDi: primaryDi)).first
    }

    public func upsert(_ devices: [UdiDevice]) throws {
        guard !devices.isEmpty else { return }

        var incomingByID: [String: UdiDevice] = [:]
        for device in devices { incomingByID[device.id] = device }

        let ids = Array(incomingByID.keys)
        let existing = try modelContext.fetch(
            FetchDescriptor<UdiDevice>(predicate: #Predicate { ids.contains($0.id) })
        )
        let existingByID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for (_, incoming) in incomingByID {
            if let existing = existingByID[incoming.id] {
                existing.update(from: incoming)
            } else {
                let newDevice = UdiDevice(primaryDi: incoming.id)
                modelContext.insert(newDevice)
                newDevice.update(from: incoming)
            }
        }

        try modelContext.save()
    }

    private func buildIdentifierPredicate(query: UdiDevicesQuery) -> Predicate<UdiDevice> {
        let primaryDi = query.primaryDi ?? ""
        let ignorePrimaryDi = query.primaryDi == nil
        let basicUdi = query.basicUdi ?? ""
        let ignoreBasicUdi = query.basicUdi == nil
        let tradeName = query.tradeName ?? ""
        let ignoreTradeName = query.tradeName == nil
        let deviceModel = query.deviceModel ?? ""
        let ignoreDeviceModel = query.deviceModel == nil

        return #Predicate<UdiDevice> { d in
            (ignorePrimaryDi || d.id == primaryDi) &&
            (ignoreBasicUdi || d.basicUdi == basicUdi) &&
            (ignoreTradeName || d.tradeName == tradeName) &&
            (ignoreDeviceModel || d.deviceModel == deviceModel)
        }
    }

    private func buildClassificationPredicate(query: UdiDevicesQuery) -> Predicate<UdiDevice> {
        let mfSrn = query.mfSrn ?? ""
        let ignoreMfSrn = query.mfSrn == nil
        let nomenclatureCode = query.nomenclatureCode ?? ""
        let ignoreNomenclatureCode = query.nomenclatureCode == nil
        let riskClassId: Int? = query.riskClassId.map { Int($0) }
        let ignoreRiskClassId = riskClassId == nil
        let applicableLegislationId: Int? = query.applicableLegislationId.map { Int($0) }
        let ignoreApplicableLegislationId = applicableLegislationId == nil

        return #Predicate<UdiDevice> { d in
            (ignoreMfSrn || d.mfSrn == mfSrn) &&
            (ignoreNomenclatureCode || d.nomenclatureCode == nomenclatureCode) &&
            (ignoreRiskClassId || d.riskClassId == riskClassId) &&
            (ignoreApplicableLegislationId || d.applicableLegislationId == applicableLegislationId)
        }
    }
}
