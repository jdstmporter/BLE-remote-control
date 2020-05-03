//
//  model.swift
//  BT
//
//  Created by Julian Porter on 03/05/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTServiceModel {
    public private(set) var identifier : CBUUID
    public private(set) var characteristics : [CBUUID]
    public private(set) var matchedTemplate : BLESerialTemplate?
    
    public var isMatched : Bool { matchedTemplate != nil }
}

class BTPeripheralModel {
    public private(set) var identifier : UUID
    public private(set) var services : [CBUUID : BTServiceModel]
    
    public var matchedServices : [CBUUID] { services.filter { $0.value.isMatched }}
    public var isMatched : Bool { matchedServices.count>0 }
}

class BTModel {
    private var peripherals : OrderedDictionary<UUID,BTPeripheralModel>
    
    
    
    
    
    
   
    
}
