//
//  WCKStore.swift
//  WCKit
//
//  Created by Anfernee Viduya on 9/16/25.
//

import Foundation

public protocol WCKStore {
    func insert<T: Codable>(_ item: T) throws
}

public enum WCKStoreError: Error {
    case unsupportedType(String)
    
    var localizedDescription: String {
        switch self {
        case .unsupportedType(let type):
            return "Unsupported type: \(type)"
        }
    }
}
