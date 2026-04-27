//
//  MockPurchasesProvider.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat
@testable import RevenueCatSubscriptionKit

/// Test double for ``PurchasesProviding``. Each async method's behaviour is
/// driven by a `Result`; helpers count call counts and let tests inject
/// snapshots through ``snapshotUpdates`` to simulate RevenueCat's
/// `PurchasesDelegate` callbacks.
final class MockPurchasesProvider: PurchasesProviding, @unchecked Sendable {

    private let lock = NSLock()
    private var _fetchResult: Result<CustomerInfoSnapshot, Error> = .success(.empty)
    private var _purchaseResult: Result<CustomerInfoSnapshot, Error> = .success(.empty)
    private var _restoreResult: Result<CustomerInfoSnapshot, Error> = .success(.empty)
    private var _offeringResult: Result<Offering?, Error> = .success(nil)

    private(set) var fetchCallCount = 0
    private(set) var purchaseCallCount = 0
    private(set) var restoreCallCount = 0
    private(set) var offeringCallCount = 0

    let snapshotUpdates: AsyncStream<CustomerInfoSnapshot>
    private let continuation: AsyncStream<CustomerInfoSnapshot>.Continuation

    init() {
        var capturedContinuation: AsyncStream<CustomerInfoSnapshot>.Continuation!
        self.snapshotUpdates = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.continuation = capturedContinuation
    }

    func setFetchResult(_ result: Result<CustomerInfoSnapshot, Error>) {
        lock.withLock { _fetchResult = result }
    }

    func setPurchaseResult(_ result: Result<CustomerInfoSnapshot, Error>) {
        lock.withLock { _purchaseResult = result }
    }

    func setRestoreResult(_ result: Result<CustomerInfoSnapshot, Error>) {
        lock.withLock { _restoreResult = result }
    }

    func setOfferingResult(_ result: Result<Offering?, Error>) {
        lock.withLock { _offeringResult = result }
    }

    func emit(_ snapshot: CustomerInfoSnapshot) {
        continuation.yield(snapshot)
    }

    func finishStream() {
        continuation.finish()
    }

    // MARK: - PurchasesProviding

    func fetchSnapshot() async throws -> CustomerInfoSnapshot {
        let result = lock.withLock { () -> Result<CustomerInfoSnapshot, Error> in
            fetchCallCount += 1
            return _fetchResult
        }
        return try result.get()
    }

    func fetchCurrentOffering() async throws -> Offering? {
        let result = lock.withLock { () -> Result<Offering?, Error> in
            offeringCallCount += 1
            return _offeringResult
        }
        return try result.get()
    }

    func purchase(_ package: Package) async throws -> CustomerInfoSnapshot {
        let result = lock.withLock { () -> Result<CustomerInfoSnapshot, Error> in
            purchaseCallCount += 1
            return _purchaseResult
        }
        return try result.get()
    }

    func restorePurchases() async throws -> CustomerInfoSnapshot {
        let result = lock.withLock { () -> Result<CustomerInfoSnapshot, Error> in
            restoreCallCount += 1
            return _restoreResult
        }
        return try result.get()
    }
}
