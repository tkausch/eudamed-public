//
// This File belongs to EudamedPublicSwift
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation


extension Operations.getActors.Input.Query {
    public init(
        ACTOR_ID: Swift.String? = nil,
        NAME: Swift.String? = nil,
        ABBREVIATED_NAME: Swift.String? = nil,
        ACTOR_TYPE: Swift.String? = nil,
        CA_NAME: Swift.String? = nil,
        CA_ACTOR_ID: Swift.String? = nil,
        ACT_COUNTRY_ISO2_CODE: Swift.String? = nil,
        _dollar_after: Swift.String? = nil
    ) {
        self.init(
            ACTOR_ID: ACTOR_ID,
            NAME: NAME,
            ABBREVIATED_NAME: ABBREVIATED_NAME,
            ACTOR_TYPE: ACTOR_TYPE,
            CA_NAME: CA_NAME,
            CA_ACTOR_ID: CA_ACTOR_ID,
            ACT_COUNTRY_ISO2_CODE: ACT_COUNTRY_ISO2_CODE,
            format: "json",
            _dollar_after: _dollar_after,
            api_hyphen_version: "v1.0"
        )
    }
}

extension Operations.getReference.Input.Query {
    public init(
        ID: Swift.Double? = nil,
        CODE: Swift.String? = nil,
        LANGUAGE: Swift.String? = nil,
        _dollar_after: Swift.String? = nil
    ) {
        self.init(
            ID: ID,
            CODE: CODE,
            LANGUAGE: LANGUAGE,
            format: "json",
            _dollar_after: _dollar_after,
            api_hyphen_version: "v1.0"
        )
    }
}

extension Operations.getUdi.Input.Query {
    public init(
        PRIMARY_DI: Swift.String? = nil,
        BASIC_UDI: Swift.String? = nil,
        TRADE_NAME: Swift.String? = nil,
        DEVICE_NAME: Swift.String? = nil,
        DEVICE_MODEL: Swift.String? = nil,
        REFERENCE: Swift.String? = nil,
        NOMENCLATURE_CODE: Swift.String? = nil,
        RISK_CLASS_ID: Swift.Double? = nil,
        APPLICABLE_LEGISLATION_ID: Swift.Double? = nil,
        PLACED_ON_THE_MARKET_ID: Swift.Double? = nil,
        MF_SRN: Swift.String? = nil,
        SPECIAL_DEVICE_TYPE_ID: Swift.Double? = nil,
        MEDICAL_PURPOSE: Swift.String? = nil,
        _dollar_after: Swift.String? = nil
    ) {
        self.init(
            PRIMARY_DI: PRIMARY_DI,
            BASIC_UDI: BASIC_UDI,
            TRADE_NAME: TRADE_NAME,
            DEVICE_NAME: DEVICE_NAME,
            DEVICE_MODEL: DEVICE_MODEL,
            REFERENCE: REFERENCE,
            NOMENCLATURE_CODE: NOMENCLATURE_CODE,
            RISK_CLASS_ID: RISK_CLASS_ID,
            APPLICABLE_LEGISLATION_ID: APPLICABLE_LEGISLATION_ID,
            PLACED_ON_THE_MARKET_ID: PLACED_ON_THE_MARKET_ID,
            MF_SRN: MF_SRN,
            SPECIAL_DEVICE_TYPE_ID: SPECIAL_DEVICE_TYPE_ID,
            MEDICAL_PURPOSE: MEDICAL_PURPOSE,
            format: "json",
            _dollar_after: _dollar_after,
            api_hyphen_version: "v1.0"
        )
    }
}
