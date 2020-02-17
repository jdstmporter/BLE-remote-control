//
//  delegates.swift
//  BT
//
//  Created by Julian Porter on 09/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation


public protocol BTCentralDelegate {
    func discovered(device: BTPeripheral,new: Bool)
    func configured(service: BTService)
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

