//
//  NetworkErrorClassifier.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat

/// Decides whether an arbitrary `Error` represents a transient network issue
/// rather than a real subscription-state problem.
///
/// The manager uses this to fall back to cached state silently when the
/// device loses connectivity, instead of surfacing a confusing error to the
/// UI.
public enum NetworkErrorClassifier {

    /// `URLError` codes that we treat as transient connectivity failures.
    static let urlErrorCodes: Set<Int> = [
        NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorTimedOut,
        NSURLErrorCannotConnectToHost,
        NSURLErrorCannotFindHost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorCallIsActive,
        NSURLErrorDataNotAllowed,
        NSURLErrorSecureConnectionFailed,
    ]

    /// Returns `true` if the error is plausibly caused by a connectivity
    /// problem rather than a programming or subscription-state error.
    public static func isNetworkError(_ error: Error) -> Bool {
        if let rcError = error as? RevenueCat.ErrorCode, rcError == .networkError {
            return true
        }
        let nsError = error as NSError
        if let code = RevenueCat.ErrorCode(rawValue: nsError.code),
           code == .networkError {
            return true
        }
        if nsError.domain == NSURLErrorDomain, urlErrorCodes.contains(nsError.code) {
            return true
        }
        return false
    }
}
