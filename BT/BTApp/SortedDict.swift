//
//  SortedDict.swift
//  BTApp
//
//  Created by Julian Porter on 17/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

public class SortedSet<K> : Sequence where K : Comparable {
    public typealias Element = K
    public typealias Iterator = Array<Element>.Iterator
    private var items : [K] = []
    
    public init() {}
    public init<E>(_ items : E) where E : Sequence, E.Element == K {
        self.items=items.sorted()
    }
    
    public func add(_ k : K) {
        guard items.contains(k) else { return }
        let idx = (items.firstIndex { $0 > k }) ?? items.endIndex
        items.insert(k, at: idx)
    }
    public func contains(_ key: K) -> Bool { items.contains(key) }
    
    public func removeValue(_ key: K) {
        guard items.contains(key) else { return }
        items=items.filter { $0 != key }
    }
    public func removeAll() { items=[] }
    
    public var count : Int { items.count }
    public subscript(_ idx : Int) -> K { items[idx] }
    public func makeIterator() -> Iterator { items.makeIterator() }
}

public class SortableSet<K> : Sequence where K : Comparable, K : Hashable {
    public typealias Element = K
    public typealias Iterator = Array<Element>.Iterator
    
    private var items : [K] = []
    private var _sorted : [K] = []
    private var needsSorting : Bool = false
    
    public init() {}
    public init<E>(_ items : E) where E : Sequence, E.Element == K {
        self.items=Array(items)
        self._sorted=items.sorted()
    }
    
    public func add(_ k : K) {
        if !items.contains(k) {
            items.append(k)
            needsSorting = true
        }
    }
    public func contains(_ key: K) -> Bool { items.contains(key) }
    public func removeValue(_ key : K) {
        items=items.filter { $0 != key }
        _sorted=_sorted.filter { $0 != key }
    }
    public func removeAll() {
        items.removeAll()
        _sorted=[]
        needsSorting=false
    }
    
    public var sorted : [Element] {
        if needsSorting {
            _sorted = items.sorted()
            needsSorting = false
            
        }
        return _sorted
    }
    
    public var count : Int { items.count }
    public subscript(_ idx : Int) -> K { sorted[idx] }
    public func makeIterator() -> Iterator { sorted.makeIterator() }
}

public class SortedDictionary<K,V> : Sequence where K: Hashable, K: Comparable {
    public typealias Element = (key: K, value: V)
    public typealias Iterator = Array<Element>.Iterator
    public typealias Keys = Array<K>
    public typealias Values = Array<V>
    
    public private(set) var keys : Keys = []
    private var dict : [K:V] = [:]
    
    public init() {}
    public init<E>(_ items : E) where E : Sequence, E.Element == (K,V) {
        items.forEach { self[$0.0] = $0.1 }
    }
    
    public subscript(_ k : K) -> V? {
        get { dict[k] }
        set {
            guard let nv = newValue else { return }
            if !keys.contains(k) {
                let idx = (keys.firstIndex { $0 > k }) ?? keys.endIndex
                keys.insert(k, at: idx)
            }
            dict[k]=nv
        }
    }
    public var count : Int { keys.count }
    public var isEmpty : Bool { keys.count==0 }
    public var values : Values { keys.map { dict[$0]! } }
    public var asArray : [Element] { keys.map { (key: $0,value: dict[$0]!) } }
    
    public var first : Element? {
        guard let k = keys.first else { return nil }
        return (key: k,value: dict[k]!)
    }
    public func contains(_ key : K) -> Bool { keys.contains(key) }
    public func removeValue(forKey key: K) -> V? {
        if keys.contains(key)  {
            keys=keys.filter { $0 != key }
            return dict.removeValue(forKey: key)
        }
        return nil
    }
    public func removeAll() {
        keys=[]
        dict.removeAll()
    }
    
    public func makeIterator() -> Iterator { asArray.makeIterator() }
    
}
