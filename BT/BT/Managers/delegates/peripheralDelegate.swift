//
//  peripheralDelegate.swift
//  BT
//
//  Created by Julian Porter on 11/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BTPeripheralManagerDelegate {
    func create(peripheral: BTPeripheral)
    func remove(peripheral: BTPeripheral)
    func update(peripheral: BTPeripheral)
}

public class BTPeripheralManager : BTPeripheralDelegate {
    
    
 
    

    
    internal enum State {
        case Disconnected
        case Connecting
        case Connected
        case Scanning
        case Ready
    }
    private var device : BTPeripheral
    private var state : State
    private var match : [CBUUID]? = nil
    private var services : [BTService] = []
    public var delegate : BTPeripheralManagerDelegate?
    
    public init(_ device: BTPeripheral,_ match : [CBUUID]? = nil) {
        self.device=device
        self.match=match
        self.state = .Disconnected
        self.device.delegate=self
    }
    
    
    public func run() {
        var next : State = state
        switch state {
        case .Disconnected:
            device.connect()
            next = .Connecting
        case .Connected:
            device.scan()
            next = .Scanning
        case .Ready:
            break
        default:
            break
        }
        state=next
    }
    
    
    
    private func tellAllCharacteristics(action: (BTCharacteristic) -> ()) {
        device.forEach { serviceID in
            let service = device[serviceID]
            service?.forEach { action($0) }
        }
    }
    
    
    public func connected() {
        state = .Connected
        SysLog.DebugLog.debug("\(device.identifier) connected")
        tellAllCharacteristics(action: { $0.delegate?.didConnect() } )
        delegate?.create(peripheral: device)
        run()
    }
    
    public func disconnected() {
        SysLog.DebugLog.debug("\(device.identifier) disconnected")
        tellAllCharacteristics(action: { $0.delegate?.didDisconnect() } )
        state = .Disconnected
        delegate?.remove(peripheral: device)
        run()
    }
    
    public func failedToConnect() {
        SysLog.DebugLog.error("\(device.identifier) failed to connect")
    }
    
    public func updatedName() {
        SysLog.DebugLog.debug("\(device.identifier) updated name")
        SysLog.DebugLog.debug(device)
        delegate?.update(peripheral: device)
    }
    
    public func readRSSI(rssi: Double) {
        SysLog.DebugLog.debug("\(device.identifier) read RSSI = \(rssi)")
        delegate?.update(peripheral: device)
    }
    
    public func discoveredServices() {
        let keys = device.serviceIDs.filter { match?.contains($0) ?? true }
        self.services = keys.compactMap { device[$0] }
        state = .Ready
        SysLog.DebugLog.debug("\(device.identifier) has discovered services matching \(match?.description ?? "<ALL>")")
        delegate?.update(peripheral: device)
        self.services.forEach { BTServiceManager($0).run() }
        
    }
    
    public func discoveredIncludedServices() {
        
    }
    
    
}
