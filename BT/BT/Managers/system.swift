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

public class OrderedDictionary<K,V> : Sequence where K : Hashable {
    
    public typealias Element = (key: K,value : V)
    public typealias Iterator = Array<Element>.Iterator
    public typealias Keys = Array<K>
    public typealias Values = Array<V>
    
    public private(set) var keys : Keys
    private var dict : [K:V]
    
    public init() {
        keys=[]
        dict=[:]
    }
    
    private func make(_ key : K?) -> Element? {
        guard let k = key, let value=dict[k] else { return nil }
        return Element(key: k, value: value)
    }
    
    public var count : Int { keys.count }
   
    public var isEmpty : Bool { count==0 }
    
    public subscript( _ key : K) -> V? {
        get { self.dict[key] }
        set {
            guard let value = newValue else { return }
            if !keys.contains(key) { keys.append(key) }
            dict[key] = value
        }
    }
    public func at(_ idx : Int) -> V? { dict[keys[idx]] }
    
    public __consuming func makeIterator() -> OrderedDictionary<K, V>.Iterator {
        self.asArray.makeIterator()
    }
    public var values : Values { self.map { $0.value } }
    public var asArray : [Element] { self.keys.compactMap { make($0) } }
    
    public func removeAll() {
        keys=[]
        dict.removeAll()
    }
    public func removeValue(forKey key : K) {
        guard keys.contains(key) else { return }
        keys.removeAll { $0 == key }
        dict.removeValue(forKey: key)
    }
    public func contains(_ key : K) -> Bool { keys.contains(key) }
    
}









