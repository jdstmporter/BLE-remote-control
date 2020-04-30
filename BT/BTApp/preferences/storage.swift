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


public protocol UserDataListener {
    var id : UUID { get }
    func valuesChanged(keys : [String])
}



extension Dictionary {
    public func intersect(keys : [Key]) -> [Key:Value] {
        keys.reduce(into: Self()) { (out : inout Self , k : Key) in out[k]=self[k] }
    }
}






 

public class UserDataManager : Sequence  {
    
    private struct ListenerWrapper : Hashable {
        public private(set) var listener : UserDataListener
        
        public init(_ listener: UserDataListener) { self.listener = listener }
        
        public func hash(into hasher: inout Hasher) { listener.id.hash(into: &hasher) }
        static public func ==(_ l : ListenerWrapper,_ r : ListenerWrapper) -> Bool { l.listener.id==r.listener.id }
    }
    
    public typealias DataDict = Dictionary<String,Any>
    public typealias Element = DataDict.Element
    public typealias Iterator = DataDict.Iterator
    
    private static var bundleID : String { Bundle.main.bundleIdentifier ?? "" }
    private static let teamID : String = "XLKATCU397"
    private static var containerID : String { "icloud.\(teamID).\(bundleID)" }
    
    private var store : NSUbiquitousKeyValueStore { .default }
    public var data : DataDict { store.dictionaryRepresentation }
    
    public private(set) var started : Bool = false
    private var listeners = Set<ListenerWrapper>()
    
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
    
    public func listen(_ listener : UserDataListener) { listeners.insert(ListenerWrapper(listener)) }
    public func unlisten(_ listener : UserDataListener) { listeners.remove(ListenerWrapper(listener))}
    public func unlisten() { listeners.removeAll() }
    
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
            listeners.forEach { $0.listener.valuesChanged(keys: names) }
            SysLog.info("iCloud keys changed: \(names.joined(separator: ", "))")
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
public let UserData = UserDataManager()

