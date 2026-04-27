//
//  CachedSubscriptionStateTests.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import Testing
@testable import RevenueCatSubscriptionKit

@Suite("CachedSubscriptionState")
struct CachedSubscriptionStateTests {

    @Test("Round-trips through JSON encoding and decoding")
    func codableRoundTrip() throws {
        let original = CachedSubscriptionState(status: .premium,
                                               isPremium: true,
                                               expirationDate: Date(timeIntervalSince1970: 1_800_000_000),
                                               updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(CachedSubscriptionState.self, from: data)

        #expect(decoded == original)
    }

    @Test("Cached state preserves nil expirationDate")
    func nilExpirationRoundTrip() throws {
        let original = CachedSubscriptionState(status: .free,
                                               isPremium: false,
                                               expirationDate: nil,
                                               updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(CachedSubscriptionState.self, from: data)

        #expect(decoded.expirationDate == nil)
        #expect(decoded == original)
    }
}
