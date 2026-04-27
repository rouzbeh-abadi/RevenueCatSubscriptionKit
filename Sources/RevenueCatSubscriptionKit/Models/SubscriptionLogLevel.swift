//
//  SubscriptionLogLevel.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat

/// The verbosity of the underlying RevenueCat SDK logs.
///
/// Mirrors `RevenueCat.LogLevel`, but defined locally so consumers don't need
/// to import RevenueCat just to configure the logger.
public enum SubscriptionLogLevel: Sendable, Equatable, Hashable {
    case verbose
    case debug
    case info
    case warn
    case error

    var revenueCatLevel: RevenueCat.LogLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warn: return .warn
        case .error: return .error
        }
    }
}
