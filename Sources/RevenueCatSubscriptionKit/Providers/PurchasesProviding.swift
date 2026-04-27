//
//  PurchasesProviding.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat

/// The minimal surface ``SubscriptionManager`` needs from RevenueCat.
///
/// In production this is implemented by ``RevenueCatPurchasesProvider``,
/// which talks to `Purchases.shared`. Tests substitute a fake conformance to
/// drive the manager through every code path without hitting the network.
public protocol PurchasesProviding: AnyObject, Sendable {

    /// A stream of customer-info snapshots produced whenever RevenueCat tells
    /// the SDK that the customer's entitlements have changed (purchase,
    /// restore, server-pushed update, …). The manager subscribes to this on
    /// configure and keeps the published state in sync.
    var snapshotUpdates: AsyncStream<CustomerInfoSnapshot> { get }

    /// Fetches the latest customer-info snapshot from RevenueCat.
    func fetchSnapshot() async throws -> CustomerInfoSnapshot

    /// Returns the current offering, or `nil` if RevenueCat has none
    /// configured.
    func fetchCurrentOffering() async throws -> Offering?

    /// Initiates a purchase for the given package and returns the snapshot
    /// reflecting the post-purchase state.
    ///
    /// Implementations should map RevenueCat's user-cancellation result into
    /// `RevenueCat.ErrorCode.purchaseCancelledError` so the manager can
    /// silently swallow it.
    func purchase(_ package: Package) async throws -> CustomerInfoSnapshot

    /// Restores any previous purchases for the current user and returns the
    /// resulting snapshot.
    func restorePurchases() async throws -> CustomerInfoSnapshot
}
