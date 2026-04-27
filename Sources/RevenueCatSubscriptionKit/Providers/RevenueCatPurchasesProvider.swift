//
//  RevenueCatPurchasesProvider.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat

/// Production implementation of ``PurchasesProviding`` that talks to
/// `Purchases.shared`.
///
/// Configures the SDK once on init and registers itself as the
/// `PurchasesDelegate` to forward `receivedUpdated` events through
/// ``snapshotUpdates``.
public final class RevenueCatPurchasesProvider: NSObject, PurchasesProviding,
                                                @unchecked Sendable {

    public let snapshotUpdates: AsyncStream<CustomerInfoSnapshot>
    private let continuation: AsyncStream<CustomerInfoSnapshot>.Continuation

    public init(configuration: SubscriptionConfiguration) {
        var capturedContinuation: AsyncStream<CustomerInfoSnapshot>.Continuation!
        self.snapshotUpdates = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.continuation = capturedContinuation
        super.init()

        Purchases.logLevel = configuration.logLevel.revenueCatLevel
        if let appUserID = configuration.appUserID {
            Purchases.configure(withAPIKey: configuration.apiKey, appUserID: appUserID)
        } else {
            Purchases.configure(withAPIKey: configuration.apiKey)
        }
        Purchases.shared.delegate = self
    }

    deinit {
        continuation.finish()
    }

    public func fetchSnapshot() async throws -> CustomerInfoSnapshot {
        let info = try await Purchases.shared.customerInfo()
        return CustomerInfoSnapshot(customerInfo: info)
    }

    public func fetchCurrentOffering() async throws -> Offering? {
        let offerings = try await Purchases.shared.offerings()
        return offerings.current
    }

    public func purchase(_ package: Package) async throws -> CustomerInfoSnapshot {
        let result = try await Purchases.shared.purchase(package: package)
        return CustomerInfoSnapshot(customerInfo: result.customerInfo)
    }

    public func restorePurchases() async throws -> CustomerInfoSnapshot {
        let info = try await Purchases.shared.restorePurchases()
        return CustomerInfoSnapshot(customerInfo: info)
    }
}

extension RevenueCatPurchasesProvider: PurchasesDelegate {

    public func purchases(_ purchases: Purchases,
                          receivedUpdated customerInfo: CustomerInfo) {
        continuation.yield(CustomerInfoSnapshot(customerInfo: customerInfo))
    }
}
