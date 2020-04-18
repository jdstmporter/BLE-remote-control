//
//  service.swift
//  BT
//
//  Created by Julian Porter on 07/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BTService : Sequence {
    public typealias Element = BTCharacteristic
    public typealias Iterator = Array<Element>.Iterator
    
    private var service : CBService
    public private(set) var identifier : CBUUID
    public private(set) var peripheral : BTPeripheral
    private var characteristics : [CBUUID:BTCharacteristic]
    public var delegate : BTServiceDelegate?
    
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
    
    public func discovered() {
        self.characteristics.removeAll()
        service.characteristics?.forEach { c in
            let characteristic=BTCharacteristic(c)
            self.characteristics[characteristic.identifier]=characteristic
        }
        delegate?.discoveredCharacteristics()
        
        let c=service.characteristics ?? []
        if c.count>0 {
            SysLog.DebugLog.debug(">> PERIPHERAL \(self.peripheral.identifier) - \(self.peripheral.localName ?? "-")")
            SysLog.DebugLog.debug(">>>> Service \(self.identifier) has \(c.count) characteristics")
        }
    }
    
    public func read(_ uuid : CBUUID) {
        self[uuid]?.read()
    }
    
    
    public func discoverCharacteristics(_ uuids: [CBUUID]? = nil) {
        self.peripheral.device.discoverCharacteristics(uuids, for: self.service)
    }
    
    
    
    public subscript(_ uuid: CBUUID) -> BTCharacteristic? { return self.characteristics[uuid] }
    public subscript(_ c: CBCharacteristic) -> BTCharacteristic? { return self.characteristics[c.uuid] }
    
}


