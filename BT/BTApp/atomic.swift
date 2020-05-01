//
//  atomic.swift
//  BTApp
//
//  Created by Julian Porter on 01/05/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

public class Atomic<T> {
    private var value : T
    private static var queue : DispatchQueue { DispatchQueue.init(label: "_Atomic_Queue_\(T.self)") }
    
    public init(_ value: T) { self.value = value }
    public func get() -> T { Atomic<T>.queue.sync { self.value }}
    public func set(_ value : T) { Atomic<T>.queue.sync { self.value = value }}
    internal func map<R>(_ f : (T) -> R) -> R { Atomic<T>.queue.sync { f(self.value) }}
    internal func update(_ f: (T) -> T) { Atomic<T>.queue.sync { self.value = f(self.value) }}
    internal func update<R>(_ f : (T) -> (T,R)) -> R {
        Atomic<T>.queue.sync {
            let out = f(self.value)
            self.value = out.0
            return out.1
        }
    }
}

public class AtomicFlag : Atomic<Bool> {
    public init() { super.init(false) }
    public func set() { self.set(true) }
    public func clear() { self.set(false) }
    public func testAndSet() -> Bool { self.update { (true, $0) }}
    public func testAndClear() -> Bool { self.update { (false, $0) }}
}
