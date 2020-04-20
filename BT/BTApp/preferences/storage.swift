//
//  storage.swift
//  BTApp
//
//  Created by Julian Porter on 20/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation



protocol KVType {}
extension Bool : KVType {}
extension Double : KVType {}
extension Int64 : KVType {}
extension String : KVType {}
extension Array : KVType  where Element : KVType {}
extension Dictionary : KVType where Key == String, Value : KVType {}


protocol UserDataManagerDelegate {
    var id : UUID { get }
    var keys : [String] { get }
    func valuesChangedExternally(_ : [String:Any])
}

extension Dictionary {
    public func intersect(keys : [Key]) -> [Key:Value] {
        keys.reduce(into: Self()) { (out : inout Self , k : Key) in out[k]=self[k] }
    }
}

class UserDataManager {
    
    private static var bundleID : String { Bundle.main.bundleIdentifier ?? "" }
    private static let teamID : String = "XLKATCU397"
    
    private static var containerID : String { "icloud.\(teamID).\(bundleID)" }
    
    private var store : NSUbiquitousKeyValueStore { .default }
    private var started : Bool = false
    
    private var listeners : [UserDataManagerDelegate] = []
    
    public init() {}
    
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
    
    public func listen(delegate: UserDataManagerDelegate) { listeners.append(delegate) }
    public func unlisten(delegate: UserDataManagerDelegate) { listeners.removeAll { $0.id == delegate.id } }
    
    @objc func callback(_ event : NSNotification) {
        guard let dict = event.userInfo else { return }
        SysLog.debug("iCloud event : \(event)")
        
        if let rn = dict[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber {
            let reason = rn.intValue
            switch reason {
            case NSUbiquitousKeyValueStoreServerChange:
                SysLog.info("Server change on iCloud")
            case NSUbiquitousKeyValueStoreInitialSyncChange:
                SysLog.info("Initial Sync on iCloud")
            case NSUbiquitousKeyValueStoreQuotaViolationChange:
                SysLog.info("Quota violation on iCloud")
            case NSUbiquitousKeyValueStoreAccountChange:
                SysLog.info("Account change on iCloud")
            default:
                SysLog.error("Unknown iCloud change reason \(reason)")
            }
        }
        if let keys = dict[NSUbiquitousKeyValueStoreChangedKeysKey] as? [NSString] {
            let names = keys.map { $0 as String }
            SysLog.info("iCloud keys changed: \(names.joined(separator: ", "))")
            let changed = store.dictionaryRepresentation.intersect(keys: names)
            listeners.forEach { listener in
                let these = changed.intersect(keys: listener.keys)
                if !these.isEmpty { listener.valuesChangedExternally(these) }
            }
        }
    }
    
    public subscript<T>(_ key : String) -> T? where T : KVType {
        get { store.object(forKey: key) as? T }
        set { store.set(newValue as Any?, forKey: key) }
    }
    
    public func set(key: String,value: KVType) { store.set(value,forKey: key) }
    
    public func get(key: String) -> String? { store.string(forKey: key) }
    public func get(key: String) -> Int64 { store.longLong(forKey: key) }
    public func get(key: String) -> Double { store.double(forKey: key) }
    public func get(key: String) -> Bool { store.bool(forKey: key) }
    public func get(key: String) -> [Any]? { store.array(forKey: key) }
    public func get(key: String) -> [String:Any]? { store.dictionary(forKey: key) }
    
    public func remove(key: String) { store.removeObject(forKey: key) }
    public var keys : [String] { Array(store.dictionaryRepresentation.keys) }
    
    public static var shared = UserDataManager()
}
