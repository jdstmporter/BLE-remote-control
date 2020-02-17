//
//  peripheralDelegate.swift
//  BT
//
//  Created by Julian Porter on 11/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

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
        print("\(device.identifier) connected")
        tellAllCharacteristics(action: { $0.delegate?.didConnect() } )
        run()
    }
    
    public func disconnected() {
        print("\(device.identifier) disconnected")
        tellAllCharacteristics(action: { $0.delegate?.didDisconnect() } )
        state = .Disconnected
        run()
    }
    
    public func failedToConnect() {
        print("\(device.identifier) failed to connect")
    }
    
    public func updatedName() {
        print("\(device.identifier) updated name")
        print(device)
    }
    
    public func readRSSI(rssi: Double) {
        print("\(device.identifier) read RSSI = \(rssi)")
    }
    
    public func discoveredServices() {
        let keys = device.serviceIDs.filter { match?.contains($0) ?? true }
        self.services = keys.compactMap { device[$0] }
        state = .Ready
        print("\(device.identifier) has discovered services matching \(match?.description ?? "<ALL>")")
        self.services.forEach { BTServiceManager($0).run() }
        
    }
    
    public func discoveredIncludedServices() {
        
    }
    
    
}
