//
//  peripheral.swift
//  BT
//
//  Created by Julian Porter on 07/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

extension UUID : Comparable {
    public static func <(_ l : UUID,_ r : UUID) -> Bool { l.uuidString < r.uuidString }
}


public class BTPeripheral : NSObject, CBPeripheralDelegate, Sequence, Comparable {
    public typealias Element = CBUUID
    public typealias Iterator = Array<Element>.Iterator
    
    private enum Actions {
        case RSSI
        case Services
    }
    
    public var delegate : BTPeripheralDelegate? 
    public private(set) var identifier : UUID
    public private(set) var rssi : Double
    public private(set) var device : CBPeripheral
    private var services : [CBUUID:BTService]
    public private(set) var uuids : [CBUUID]
    private var ads : [String:Any]
    
    public private(set) var matchedTemplate : BLESerialTemplate?
    
    public init(_ device : CBPeripheral,advertisementData: [String: Any] = [:],rssi: Double) {
        self.device = device
        self.identifier = device.identifier
        self.rssi = rssi
        self.services = [:]
        self.ads = advertisementData
        self.uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        super.init()
        self.device.delegate = self
    }
    public var localName : String? { return device.name }
    public var state : CBPeripheralState { return device.state }
    public var connected : Bool { return state == .connected }
    
    
    public func connect() {
        if state == .disconnected {
            BTCentral.shared.connect(self)
        }
    }
    
    public func hasAdUUID(_ uuid : CBUUID) -> Bool { return uuids.contains(uuid) }
    public func hasServiceUUID(_ uuid : CBUUID) -> Bool { return services[uuid] != nil }
    
    public func scan(services : [CBUUID]? = nil) {
        device.discoverServices(services)
    }
    
    @discardableResult public func match(_ templates : [BLESerialTemplate]) -> Bool {
        matchedTemplate = templates.first { uuids.contains($0.service) }
        return matchedTemplate != nil
    }
    public var isMatched : Bool { matchedTemplate != nil }
    public var matchedService : BTService? {
        guard let uuid = matchedTemplate?.service else { return nil }
        return services[uuid]
    }
    
    
    private func servicesFound() {
        let s = device.services ?? []
        s.forEach { service in
            let bts = BTService(service, peripheral: self)
            self.services[bts.identifier]=bts
        }
        delegate?.discoveredServices()
    }
    
    public func makeIterator() -> Array<BTPeripheral.Element>.Iterator {
        return Array(services.keys).makeIterator()
    }
    public var serviceIDs : [CBUUID] { return Array(self.services.keys) }
    
    public subscript(_ uuid: CBUUID) -> BTService? { return self.services[uuid] }
    public subscript(_ uuid: BTUUID) -> BTService? { return self.services[uuid.uuid] }
    public subscript(_ service: CBService) -> BTService? { return self.services[service.uuid] }
    public subscript(_ ch: CBCharacteristic) -> BTService? { return self.services[ch.service.uuid] }
    
    public var canWriteWithoutResponse : Bool { return device.canSendWriteWithoutResponse }
    public func maxWriteLength(mode : CBCharacteristicWriteType = .withResponse) -> Int {
        return device.maximumWriteValueLength(for: mode)
    }
    
    
    // delegate methods
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        SysLog.debug("Peripheral \(identifier) : local name updated: \(localName ?? "")")
        delegate?.updatedName()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier) : get RSSI error \(e)")
            return
        }
        rssi=RSSI.doubleValue
        SysLog.debug("Peripheral \(identifier) : RSSI: \(rssi)")
        delegate?.readRSSI(rssi: rssi)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier) : discover services error \(e)")
            return
        }
        if let s=peripheral.services {
            SysLog.debug("Peripheral \(identifier) [\(localName ?? "nil")]")
            SysLog.debug(">> Found services:")
            s.forEach { SysLog.debug("    \($0)") }
            servicesFound()
        }
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        SysLog.error("Peripheral \(identifier) : Invalidated \(invalidatedServices)")
        device.discoverServices(nil)
    }
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        delegate?.discoveredIncludedServices()
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier) : discover characteristics error \(e)")
            return
        }
        self[service]?.discovered()
    }
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier), characteristic \(characteristic.uuid) : discover characteristic value error \(e)")
            let ns=e as NSError
            SysLog.error("NSError \(ns)")
            
            return
        }
        if let service = self[characteristic], let c=service[characteristic] {
            service.delegate?.updatedCharacteristic(c)
            
        }
    }
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier) : discover descriptors error \(e)")
            return
        }
        
        
    }
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier) : discover descriptor value error \(e)")
            return
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier) : update notifications error \(e)")
            return
        }
        SysLog.debug("Peripheral \(identifier) Updated notification state for \(characteristic.uuid)")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e=error {
            SysLog.error("Peripheral \(identifier) : write error \(e)")
            return
        }
        SysLog.debug("Peripheral \(identifier) wrote data to \(characteristic.uuid)")
    }
    
    
    public override var description: String {
        var lines : [String]=[]
        lines.append(">> Device \(identifier) : \(localName ?? "-")")
        lines.append("  RSSI = \(rssi)")
        lines.append("  UUIDS = \(uuids)")
        //ads.forEach { kv in lines.append("  \(kv.key) -> '\(kv.value)'") }
        return lines.joined(separator: "\n")
    }
    
    public static func ==(_ l : BTPeripheral,_ r : BTPeripheral) -> Bool { l.identifier==r.identifier }
    public static func <(_ l : BTPeripheral,_ r : BTPeripheral) -> Bool { l.identifier<r.identifier }
    

}


