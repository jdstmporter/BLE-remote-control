//
//  storage.swift
//  BTApp
//
//  Created by Julian Porter on 20/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation



public protocol KVType {}
extension Bool : KVType {}
extension Double : KVType {}
extension Int64 : KVType {}
extension String : KVType {}
extension Array : KVType  where Element : KVType {}
extension Dictionary : KVType where Key == String, Value : KVType {}


public protocol UserDataManagerDelegate {
    var id : UUID { get }
    func valuesChanged(keys : [String])
    func valuesLoaded(keys: [String])
}

extension Dictionary {
    public func intersect(keys : [Key]) -> [Key:Value] {
        keys.reduce(into: Self()) { (out : inout Self , k : Key) in out[k]=self[k] }
    }
}

public class UserDataManager : Sequence  {
    public typealias Element = Dictionary<String,Any>.Element
    public typealias Iterator = Dictionary<String,Any>.Iterator
    
    public static let UserDataManagerNotification = Notification.Name("__BT_USER_DATA_MANAGER_CHANGE")
    
    private static var bundleID : String { Bundle.main.bundleIdentifier ?? "" }
    private static let teamID : String = "XLKATCU397"
    
    private static var containerID : String { "icloud.\(teamID).\(bundleID)" }
    
    private var store : NSUbiquitousKeyValueStore { .default }
    public private(set) var started : Bool = false
    
    private var data : [String:Any] = [:]
    
    public  init() {}
    
    public func start() {
        guard !started else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(callback(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
        store.synchronize()
        data=store.dictionaryRepresentation
        started=true
    }
    
    public func stop() {
        guard started else { return }
        started=false
        NotificationCenter.default.removeObserver(self, name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
    }
    
     
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
            data=store.dictionaryRepresentation
            let names = keys.map { $0 as String }
            SysLog.info("iCloud keys changed: \(names.joined(separator: ", "))")
            NotificationCenter.default.post(name: UserDataManager.UserDataManagerNotification,
                                            object: self,
                                            userInfo: ["keys" : names])
        }
    }
    
    public subscript<T>(_ key : String) -> T?  {
        get { data[key] as? T }
        set {
            if let nv = newValue {
                data[key] = nv
                store.set(nv, forKey: key)
            }
            else {
                data.removeValue(forKey: key)
                store.removeObject(forKey: key)
            }
        }
    }
    
    public func remove(key: String) { store.removeObject(forKey: key) }
    public var keys : [String] { Array(data.keys) }
    
    public var count : Int { data.count }
    public func makeIterator() -> Dictionary<String, Any>.Iterator { data.makeIterator() }

    
    
    
    
}
public let UserData = UserDataManager()

