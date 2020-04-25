//
//  main.swift
//  BTTest
//
//  Created by Julian Porter on 24/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

public class UserDataManager : Sequence  {

public typealias DataDict = Dictionary<String,Any>
public typealias Element = DataDict.Element
public typealias Iterator = DataDict.Iterator

private static var bundleID : String { "org.porternet.ble" }
private static let teamID : String = "XLKATCU397"
private static var containerID : String { "icloud.\(teamID).\(bundleID)" }

private var store : NSUbiquitousKeyValueStore { .default }
public var data : DataDict { store.dictionaryRepresentation }

public private(set) var started : Bool = false

public  init() {}

public func start() {
    guard !started else { return }
    NotificationCenter.default.addObserver(self, selector: #selector(callback(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
    store.synchronize()
    started=true
}

public func stop() {
    guard started else { return }
    started=false
    NotificationCenter.default.removeObserver(self, name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
}
    



@objc func callback(_ event : NSNotification) {
    guard let dict = event.userInfo else { return }
    print("iCloud event : \(event)")
    
    if let rn = dict[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber {
        let reason = rn.intValue
        switch reason {
        case NSUbiquitousKeyValueStoreServerChange:
            print("Server change on iCloud")
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            print("Initial Sync on iCloud")
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("Quota violation on iCloud")
        case NSUbiquitousKeyValueStoreAccountChange:
            print("Account change on iCloud")
        default:
            print("Unknown iCloud change reason \(reason)")
        }
    }
    if let keys = dict[NSUbiquitousKeyValueStoreChangedKeysKey] as? [NSString] {
        let names = keys.map { $0 as String }
        print("iCloud keys changed: \(names.joined(separator: ", "))")
    }
}

public subscript<T>(_ key : String) -> T?  {
    get { data[key] as? T }
    set {
        if let nv = newValue { store.set(nv, forKey: key) }
        else { store.removeObject(forKey: key) }
    }
}

public func remove(key: String) { store.removeObject(forKey: key) }
public var keys : [String] { Array(data.keys) }

public var count : Int { data.count }
public func makeIterator() -> Dictionary<String, Any>.Iterator { data.makeIterator() }

    
}

do {
    let b = UserDataManager()
    b.start()
    if b.count==0 { print("No values") }
    else {
        print("\(b.count) values")
        b.forEach { print("\($0.key) -> \($0.value)")}
    }
    b.stop()
}
catch let e { print("Error : \(e)") }

