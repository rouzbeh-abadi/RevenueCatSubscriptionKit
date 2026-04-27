//
//  NetworkErrorClassifierTests.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat
import Testing
@testable import RevenueCatSubscriptionKit

@Suite("NetworkErrorClassifier")
struct NetworkErrorClassifierTests {

    @Test("URLError(.notConnectedToInternet) is a network error")
    func notConnected() {
        let error = URLError(.notConnectedToInternet)
        #expect(NetworkErrorClassifier.isNetworkError(error))
    }

    @Test("URLError(.timedOut) is a network error")
    func timedOut() {
        let error = URLError(.timedOut)
        #expect(NetworkErrorClassifier.isNetworkError(error))
    }

    @Test("URLError(.networkConnectionLost) is a network error")
    func connectionLost() {
        let error = URLError(.networkConnectionLost)
        #expect(NetworkErrorClassifier.isNetworkError(error))
    }

    @Test("URLError(.cannotFindHost) is a network error")
    func cannotFindHost() {
        let error = URLError(.cannotFindHost)
        #expect(NetworkErrorClassifier.isNetworkError(error))
    }

    @Test("Generic NSError outside URLErrorDomain is not a network error")
    func nonURLNotNetwork() {
        let error = NSError(domain: "com.example.something", code: 42)
        #expect(!NetworkErrorClassifier.isNetworkError(error))
    }

    @Test("URLError code outside the recognised list is not a network error")
    func unknownURLCodeNotNetwork() {
        let error = NSError(domain: NSURLErrorDomain, code: -999_999)
        #expect(!NetworkErrorClassifier.isNetworkError(error))
    }

    @Test("RevenueCat .networkError is detected")
    func revenueCatNetworkError() {
        let code = RevenueCat.ErrorCode.networkError
        #expect(NetworkErrorClassifier.isNetworkError(code))
    }

    @Test("RevenueCat .purchaseCancelledError is not a network error")
    func revenueCatCancelNotNetwork() {
        let code = RevenueCat.ErrorCode.purchaseCancelledError
        #expect(!NetworkErrorClassifier.isNetworkError(code))
    }
}
