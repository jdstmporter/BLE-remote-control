//
//  centralDelegate.swift
//  BT
//
//  Created by Julian Porter on 11/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BTSystemManager : BTCentralDelegate {
    
    private static let queue = DispatchQueue(label: "BTEnumerateQueue", qos: .background)
    
    private var managers : [BTPeripheralManager] = []
    public private(set) var services : [CBUUID]? = nil
    public var delegate : BTPeripheralManagerDelegate?
    
    public init(services : [CBUUID]? = nil) {
        self.services=services
        BTCentral.shared.delegate=self
    }
    
    public init(services : [String]) {
        let uuids = services.map { CBUUID(string: $0) }
        self.services=uuids
        BTCentral.shared.delegate=self
    }
    
    public func startScan() {
        BTSystemManager.queue.async { BTCentral.shared.scan(services: self.services) }
    }
    public func stopScan() {
        BTSystemManager.queue.async { BTCentral.shared.stopScan() }
    }
    
    
    public func configured(service: BTService) {
        SysLog.debug("Have configured service \(service)")
        //delegate?.update(peripheral: service.peripheral)
    }
    
    
    
    public func discovered(device: BTPeripheral, new: Bool) {
        SysLog.info("Discovered peripheral (is new: \(new)):")
        SysLog.info(device.description)
        if new {
            let mgr = BTPeripheralManager(device,services)
            mgr.delegate=delegate
            mgr.run()
            managers.append(mgr)
        }
        
        
    }
    
    public func changedState() {
        SysLog.info("Central manager has changed state: \(BTCentral.shared.state)")
        delegate?.systemStateChanged(alive: BTCentral.shared.alive)
        //if BTCentral.shared.alive {
        //    BTCentral.shared.scan(services: services)
        //}
    }
    
    
}
