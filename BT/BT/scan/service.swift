//
//  service.swift
//  BT
//
//  Created by Julian Porter on 07/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BTService : BTServiceDelegate, Sequence {
    public typealias Element = BTCharacteristic
    public typealias Iterator = Array<Element>.Iterator
    
    private var service : CBService
    public private(set) var identifier : CBUUID
    public private(set) var peripheral : BTPeripheral
    private var characteristics : [CBUUID:BTCharacteristic]
    public var delegate : BTPeripheralManagerDelegate?
    //public var delegate : BTServiceDelegate?
    public private(set) var matchedTemplate : BLESerialTemplate?
    
    public init(_ service : CBService, peripheral : BTPeripheral) {
        self.service=service
        self.identifier=service.uuid
        self.peripheral=peripheral
        self.characteristics=[:]
    }
    
    public var connected : Bool { return peripheral.connected }
    public var primary : Bool { return service.isPrimary }
    public var uuids : [CBUUID] { return Array(characteristics.keys) }
    public var count : Int { return service.characteristics?.count ?? 0 }
    public func makeIterator() -> Array<BTService.Element>.Iterator {
        let a=Array(characteristics.values)
        return a.makeIterator()
    }
    public subscript(_ uuid: CBUUID) -> BTCharacteristic? { return self.characteristics[uuid] }
    public subscript(_ c: CBCharacteristic) -> BTCharacteristic? { return self.characteristics[c.uuid] }
    
    public func read(_ uuid : CBUUID) { self[uuid]?.read() }
    public func readAll() { self.forEach { $0.read() } }
    
    
    public func run() {
        self.peripheral.device.discoverCharacteristics(nil, for: self.service)
    }
    
    private var matched : Bool? = nil {
        didSet {
            if matched != oldValue {
                SysLog.debug("Have configured service \(service)")
                delegate?.update(peripheral: peripheral)
            }
        }
    }
    
    public var isMatched : Bool { matchedTemplate != nil }
    public var isWeakMatch : Bool { Templates.match(self) != nil }
    
    @discardableResult public func matches() -> Bool {
        if let m = Templates.match(self), self[m.rx] != nil, self[m.tx] != nil {
            self.matchedTemplate = m
        }
        else { self.matchedTemplate = nil }
        return self.matchedTemplate != nil
    }
    
    // callbacks
    
    
    public func discoveredCharacteristics() {
        self.characteristics.removeAll()
        service.characteristics?.forEach { c in
            let characteristic=BTCharacteristic(c)
            self.characteristics[characteristic.identifier]=characteristic
        }
        matched = matches()
        readAll()
        //delegate?.discoveredCharacteristics()
        
        let c=service.characteristics ?? []
        if c.count>0 {
            SysLog.debug(">> PERIPHERAL \(self.peripheral.identifier) - \(self.peripheral.localName ?? "-")")
            SysLog.debug(">>>> Service \(self.identifier) has \(c.count) characteristics")
        }
    }
    
    public func updatedCharacteristic(_ characteristic: BTCharacteristic) {
        guard let v=characteristic.bytes else { return }
        SysLog.debug(">>>> Characteristic \(characteristic.identifier) on \(identifier) has discovered value")
        SysLog.debug(characteristic)
        delegate?.receivedValue(v, onService: identifier, characteristic: characteristic.identifier)
    }
    
   
    
  
    

    
}


