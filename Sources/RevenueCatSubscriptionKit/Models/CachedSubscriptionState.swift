//
//  CachedSubscriptionState.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// A persisted snapshot of subscription state.
///
/// The manager writes one of these to its ``SubscriptionCache`` after every
/// successful refresh, and reads it back at launch to give the UI a sensible
/// starting value before the first network round-trip completes (or when the
/// device is offline).
public struct CachedSubscriptionState: Codable, Equatable, Sendable {

    public let status: SubscriptionStatus
    public let isPremium: Bool
    public let expirationDate: Date?
    public let updatedAt: Date

    public init(status: SubscriptionStatus,
                isPremium: Bool,
                expirationDate: Date?,
                updatedAt: Date) {
        self.status = status
        self.isPremium = isPremium
        self.expirationDate = expirationDate
        self.updatedAt = updatedAt
    }
}
