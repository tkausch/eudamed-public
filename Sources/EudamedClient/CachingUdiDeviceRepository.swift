//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import SwiftData

public actor CachingUdiDeviceRepository: UdiDevicesRepository {

    private let remote: RemoteUdiDevicesRepository
    private let local: LocalUdiDevicesRepository
    public private(set) var lastSync: Date?

    public init(modelContainer: ModelContainer) throws {
        self.remote = try RemoteUdiDevicesRepository()
        self.local = LocalUdiDevicesRepository(modelContainer: modelContainer)
    }

    init(modelContainer: ModelContainer, remote: RemoteUdiDevicesRepository) {
        self.remote = remote
        self.local = LocalUdiDevicesRepository(modelContainer: modelContainer)
    }

    public func search(query: UdiDevicesQuery = UdiDevicesQuery()) async throws -> [UdiDevice] {
        try await local.search(query: query)
    }

    public func device(primaryDi: String) async throws -> UdiDevice? {
        try await local.device(primaryDi: primaryDi)
    }

    public func sync(query: UdiDevicesQuery = UdiDevicesQuery()) async throws {
        let devices = try await remote.search(query: query)
        try await local.upsert(devices)
        lastSync = .now
    }
}
