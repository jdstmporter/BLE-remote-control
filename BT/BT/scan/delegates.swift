//
//  delegates.swift
//  BT
//
//  Created by Julian Porter on 09/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BTEntity {
    
}


public protocol BTSystemManagement {
    
    var templates : [BLESerialTemplate] { get set }
    var scanning : Bool { get }
    
    func startScan()
    func stopScan()
}
public protocol BTBasicDelegate {
    func run()
    var delegate : BTPeripheralManagerDelegate? { get set }
}





public protocol BTPeripheralManagerDelegate {

    func create(peripheral: BTPeripheral)
    func remove(peripheral: BTPeripheral)
    func update(peripheral: BTPeripheral)
    
    func systemStateChanged(alive: Bool)
    func receivedValue(_ : Data,onService: CBUUID, characteristic: CBUUID)
    var timeoutValue : Double { get }
}

public protocol BTCentralDelegate {
    func discovered(device: BTPeripheral,new: Bool)
    func changedState()
    
}

public protocol BTPeripheralDelegate {
    func connected()
    func disconnected()
    func failedToConnect()
    
    func updatedName()
    func readRSSI(rssi: Double)
    
    func discoveredServices()
    func discoveredIncludedServices()
}


public protocol BTServiceDelegate {
    func discoveredCharacteristics()
    func updatedCharacteristic(_ characteristic: BTCharacteristic)
}

public protocol BTCharacteristicDelegate {
    func receivedValue(_ : Data)
    func didConnect()
    func didDisconnect()
}

