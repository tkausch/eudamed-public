//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import os.log

private let logger = Logger(subsystem: "EudamedDataModel", category: "udi")

public actor CachingUdiDevicesRepository: UdiDevicesRepository {

    private var cachedDevices = [UdiDevice]()

    private let remote: (any UdiDevicesRepository)?

    public init() {
        self.remote = try? RemoteUdiDevicesRepository()
    }

    init(remote: any UdiDevicesRepository) {
        self.remote = remote
    }

    public func search(query: UdiDevicesQuery = UdiDevicesQuery()) async throws -> [UdiDevice] {
        let cached = searchFromCache(query: query)
        guard cached.isEmpty else {
            logger.debug("cache hit: returning \(cached.count) device(s) from cache")
            return cached
        }
        return try await loadFromRemoteAndCache(query: query)
    }

    public func device(primaryDi: String) async throws -> UdiDevice? {
        try await search(query: UdiDevicesQuery(primaryDi: primaryDi)).first
    }

    private func searchFromCache(query: UdiDevicesQuery) -> [UdiDevice] {
        cachedDevices.filter { device in
            if let primaryDi = query.primaryDi, device.primaryDi != primaryDi { return false }
            if let basicUdi = query.basicUdi, device.basicUdi != basicUdi { return false }
            if let tradeName = query.tradeName, device.tradeName != tradeName { return false }
            if let deviceName = query.deviceName, device.deviceName != deviceName { return false }
            if let deviceModel = query.deviceModel, device.deviceModel != deviceModel { return false }
            if let reference = query.reference, device.reference != reference { return false }
            if let nomenclatureCode = query.nomenclatureCode, device.nomenclatureCode != nomenclatureCode { return false }
            if let riskClassId = query.riskClassId, device.riskClassId != Int(riskClassId) { return false }
            if let mfSrn = query.mfSrn, device.mfSrn != mfSrn { return false }
            return true
        }
    }

    private func loadFromRemoteAndCache(query: UdiDevicesQuery) async throws -> [UdiDevice] {
        guard let newDevices = try await remote?.search(query: query) else { return [] }
        cachedDevices += newDevices
        return newDevices
    }
}
