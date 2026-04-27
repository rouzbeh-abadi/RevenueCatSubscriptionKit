//
//  PurchaseCancellationClassifierTests.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat
import Testing
@testable import RevenueCatSubscriptionKit

@Suite("PurchaseCancellationClassifier")
struct PurchaseCancellationClassifierTests {

    @Test("Recognises a direct ErrorCode value")
    func directErrorCode() {
        let error: Error = RevenueCat.ErrorCode.purchaseCancelledError
        #expect(PurchaseCancellationClassifier.isUserCancellation(error))
    }

    @Test("Recognises an NSError carrying the cancellation code")
    func nsErrorCarryingCode() {
        let error = NSError(domain: "RevenueCat",
                            code: RevenueCat.ErrorCode.purchaseCancelledError.rawValue)
        #expect(PurchaseCancellationClassifier.isUserCancellation(error))
    }

    @Test("Other RevenueCat errors are not cancellations")
    func otherCodeNotCancellation() {
        let error: Error = RevenueCat.ErrorCode.networkError
        #expect(!PurchaseCancellationClassifier.isUserCancellation(error))
    }

    @Test("Generic NSError is not a cancellation")
    func unrelatedErrorNotCancellation() {
        let error = NSError(domain: "com.example", code: 99)
        #expect(!PurchaseCancellationClassifier.isUserCancellation(error))
    }
}
