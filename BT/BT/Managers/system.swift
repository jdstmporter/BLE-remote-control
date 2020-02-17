//
//  system.swift
//  BT
//
//  Created by Julian Porter on 09/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct ServiceCharacteristic {
    public let service : CBUUID
    public let characteristic : CBUUID
    public let notify : Bool
}

struct ListDict<Key,Value> where Key : Hashable {
    private var dict : [Key:[Value]] = [:]
    
    public subscript(_ key : Key) -> [Value] {
        get { return dict[key] ?? [] }
        set { dict[key]=newValue }
    }
    public var keys : Set<Key> { return Set(dict.keys) }
    public func has(_ key : Key) -> Bool { return dict[key] != nil }
    public mutating func append(_ key : Key,_ value : [Value]) {
        var i=self[key]
        i.append(contentsOf: value)
        self[key]=i
    }
    public mutating func append(_ key : Key,_ value : Value) {
        self.append(key,[value])
    }
    
}




