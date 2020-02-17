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
    
    private var managers : [BTPeripheralManager] = []
    public private(set) var services : [CBUUID]? = nil
    
    public init(services : [CBUUID]? = nil) {
        self.services=services
        BTCentral.shared.delegate=self
    }
    
    public init(services : [String]) {
        let uuids = services.map { CBUUID(string: $0) }
        self.services=uuids
        BTCentral.shared.delegate=self
    }
    
    
    public func configured(service: BTService) {
        print("Have configured servce \(service)")
    }
    
    
    
    public func discovered(device: BTPeripheral, new: Bool) {
        print("Discovered peripheral (is new: \(new)):")
        print(device)
        if new {
            let mgr = BTPeripheralManager(device,services)
            mgr.run()
            managers.append(mgr)
        }
        
        
    }
    
    public func changedState() {
        print("Central manager has changed state: \(BTCentral.shared.state)")
        if BTCentral.shared.alive {
            BTCentral.shared.scan(services: services)
        }
    }
    
    
}
