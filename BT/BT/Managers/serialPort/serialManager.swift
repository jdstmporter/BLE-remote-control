//
//  serialManager.swift
//  BT
//
//  Created by Julian Porter on 13/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BLESerialDevicesDelegate {
    func discoveredSerialPort(_ : BLESerialPort)
}



public class BLESerialDevices<PORT : BLESerialPort> : Sequence {
    public typealias Element = BLESerialPort
    public typealias Iterator = Array<Element>.Iterator
    
    public enum NError : Error {
        case NoUserInfo
        case NoServiceKey
        case NotAService
        case NotASerialPort
    }
    
    private var service: CBUUID
    private var characteristic : CBUUID
    public private(set) var devices : [BLESerialPort]
    private var scanner : BTSystemManager!
    public var delegate : BLESerialDevicesDelegate?
    
    public init(service : CBUUID,characteristic : CBUUID) {
        self.service=service
        self.characteristic=characteristic
        self.devices=[]
    }
    
    public var count : Int { return devices.count }
    public var ids : [UUID] { return devices.map { $0.device.identifier }}
    public subscript(_ id : UUID) -> BLESerialPort? { return devices.first {  $0.device.identifier == id } }
    public func makeIterator() -> Array<Element>.Iterator {
        return devices.makeIterator()
    }
    
    private func process(_ notification: Notification) throws {
        guard let info = notification.userInfo  else { throw NError.NoUserInfo }
        guard let raw = info["service"] else { throw NError.NoServiceKey }
        guard let service = raw as? BTService else { throw NError.NotAService }
        
        SysLog.debug("****** FOUND SERVICE ")
        SysLog.debug("\(service)")
        
        guard let serial = PORT(service, rxtx: self.characteristic) else { throw NError.NotASerialPort }
        self.devices.append(serial)
        self.delegate?.discoveredSerialPort(serial)
    }
    
 
    
    public func start() {
        
        NotificationCenter.default.addObserver(forName: BTServiceManager.BTServiceDiscoveredEvent, object: nil, queue: nil) { notification in
            do {
                try self.process(notification)
            }
            catch let e { SysLog.error("Error : \(e)") }
        }
        scanner = BTSystemManager(services: [service])
    }
    
    
}

struct BTUUID : Hashable, Equatable, CustomStringConvertible {
    
    public private(set) var uuid : CBUUID
    
    public init(_ uuid : CBUUID) {
        self.uuid=uuid
    }
    public init(_ uuid : UUID) {
        self.uuid=CBUUID(nsuuid: uuid)
    }
    public init(_ uuid : String) {
        self.uuid=CBUUID.init(string: uuid)
    }
    
    func hash(into hasher: inout Hasher) {
        uuid.hash(into: &hasher)
    }
    
    public static func ==(_ l : BTUUID, _ r : BTUUID) -> Bool { return l.uuid==r.uuid }
    public static func ==(_ l : BTUUID, _ r : CBUUID) -> Bool { return l==BTUUID(r) }
    public static func ==(_ l : BTUUID, _ r : UUID)   -> Bool { return l==BTUUID(r) }
    public static func ==(_ l : BTUUID, _ r : String) -> Bool { return l==BTUUID(r) }
    public static func ==(_ r : CBUUID, _ l : BTUUID) -> Bool { return l==BTUUID(r) }
    public static func ==(_ r : UUID,   _ l : BTUUID) -> Bool { return l==BTUUID(r) }
    public static func ==(_ r : String, _ l : BTUUID) -> Bool { return l==BTUUID(r) }
    
    public var description: String { return uuid.description }
    
    
}


