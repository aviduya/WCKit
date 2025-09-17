//
//  WCKTransferable.swift
//  WCKit
//
//  Created by Anfernee Viduya on 9/16/25.
//

public protocol WCKTransferable: Codable {
    static var typeKey: String { get }
}
