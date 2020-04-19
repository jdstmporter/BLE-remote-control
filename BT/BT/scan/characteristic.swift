//
//  characteristic.swift
//  BT
//
//  Created by Julian Porter on 08/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

extension CBCharacteristicProperties : Hashable {
    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
    
    private static let lookup : [CBCharacteristicProperties:String] = [
        .broadcast : "BROADCAST",
        .read : "READABLE",
        .writeWithoutResponse : "WRITE_NO_RESPONSE",
        .write : "WRITEABLE",
        .notify : "NOTIFIABLE",
        .indicate : "NOTIFIABLE_WITH_RECEIPT",
        .authenticatedSignedWrites : "SIGNED_WRITES",
        .extendedProperties : "EXTENDED",
        .notifyEncryptionRequired : "NOTIFY_REQUIRES_TRUST",
        .indicateEncryptionRequired : "NOTIFY_WITH_RECEIPT_REQUIRES_TRUST"
    ]
    
    public var expand : String {
        let a = CBCharacteristicProperties.lookup.compactMap { self.contains($0.key) ? $0.value : nil }
        return "<\(a.joined(separator:","))>"
    }
}

public class BTDescriptor : CustomStringConvertible {
    public enum BTType : CaseIterable {
        private typealias Test = (Any?) -> Bool
        case Null
        case String
        case Data
        case Number
        case Other
    }
    
    public private(set) var identifier : CBUUID
    public private(set) var raw : Any?
    public private(set) var type : BTType
    
    
    public init(_ descriptor : CBDescriptor) {
        identifier = descriptor.uuid
        raw = descriptor.value
        
        if let r = raw {
            if let _ = r as? Data { type = .Data }
            else if let _ = r as? String { type = .String }
            else if let _ = r as? NSNumber { type = .Number }
            else { type = .Other }
        }
        else {
            type = .Null
        }
    }
    
    public var description: String {
        var str : String = ""
        switch type {
        case .Null:
            str = "\(identifier):<NULL>"
        case .Data:
            str = "\(identifier):<DATA:\((raw! as! Data).hex)>"
        case .String:
            str = "\(identifier):<STRING:\(raw! as! String)"
        case .Number:
            str = "\(identifier):<NUMBER:\(raw! as! NSNumber)"
        default:
            str = "\(identifier):<UNKNOWN:\(raw!)>"
        }
        return str
    }
}

public class FIFO<T> {
    private var queue : [T] = []
    
    public func push(_ v : T) { queue.append(v) }
    public func pop() -> T? {
        guard queue.count>0 else { return nil }
        return queue.removeFirst()
    }
    public var first : T? { return queue.first }
    public var last : T? { return queue.last }
    public var count : Int { return queue.count }
    public var ready : Bool { return queue.count>0 }
}

public class BTCharacteristic : CustomStringConvertible {
    
    public static let Bad : [CBUUID] = [CBUUID(string:"2A19"),CBUUID(string:"2A0F"),CBUUID(string:"2A2B")]
    
    private var characteristic : CBCharacteristic
    public private(set) var identifier : CBUUID
    public private(set) var service : CBService
    private var queue : FIFO<Data>
    public var delegate : BTCharacteristicDelegate?
    
    public init(_ characteristic : CBCharacteristic) {
        self.characteristic=characteristic
        self.identifier=characteristic.uuid
        self.service=characteristic.service
        self.queue=FIFO()
    }
    public var notifying : Bool { return characteristic.isNotifying }
    public var readable : Bool { return characteristic.properties.contains(.read) }
    public var writeable : Bool { return characteristic.properties.contains(.write) }
    
    public var bad : Bool { return BTCharacteristic.Bad.contains(identifier) }
    public var hasValue : Bool { return bytes != nil }
    
    private var peripheral : CBPeripheral { return self.service.peripheral }
    
    public func read() {
        if readable && !bad {
            peripheral.readValue(for: characteristic)
        }
        SysLog.debug(">>>> Characteristic \(self.identifier) on \(self.service) has")
        SysLog.debug(self)
    }
    
    public func write(_ data : Data,mode : CBCharacteristicWriteType = .withResponse) {
        if writeable {
            peripheral.writeValue(data, for: characteristic, type: mode)
        }
    }
    
    
    public func notify(_ on : Bool) {
        peripheral.setNotifyValue(on, for: characteristic)
    }
    
    public var bytes : Data? {
        return self.characteristic.value
    }
    public var str : String? {
        guard let v=bytes else { return nil }
        return String(data: v, encoding: .utf8)
    }
    
    
    public var description: String {
        var lines : [String] = []
        if let s=str { lines.append("**     value = \(s) <STR>") }
        else if let b=bytes { lines.append("**     value = \(b.hex) <HEX>") }
        else { lines.append("**     value = <NULL>") }
        lines.append("       properties = \(self.characteristic.properties.expand)")
        return lines.joined(separator: "\n")
    }
    
}



