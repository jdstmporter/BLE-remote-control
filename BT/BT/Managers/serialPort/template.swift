//
//  template.swift
//  BT
//
//  Created by Julian Porter on 27/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth


public struct BLESerialTemplate : CustomStringConvertible {
    public private(set) var service : CBUUID
    public private(set) var rx : CBUUID
    public private(set) var tx : CBUUID
    public private(set) var name : String
    
    init(service : CBUUID, rxtx : (CBUUID,CBUUID), name : String = "") {
        self.service=service
        self.rx=rxtx.0
        self.tx=rxtx.1
        self.name=name
    }
    init(service : CBUUID, rxtx : CBUUID, name : String = "") {
        self.init(service: service, rxtx: (rxtx,rxtx), name: name)
    }
    
    
    init?(key : String, values : [String:Any]) {
        guard let s = values["service"] as? String,
            let r = values["rx"] as? String,
            let t = values["tx"] as? String else { return nil }
        self.service=CBUUID(string: s)
        self.rx=CBUUID(string: r)
        self.tx=CBUUID(string: t)
        self.name=key
    }
    
    init(_ port : BLESerialPort, name : String? = nil) {
        self.service=port.service.identifier
        self.rx=port.rx.identifier
        self.tx=port.tx.identifier
        self.name = name ?? port.deviceName ?? ""
    }
    
    
    
    func implementedBy(_ p : BTPeripheral) -> Bool {
        BLEBaseSerial(peripheral: p, template: self) != nil
    }
    
    var serialised : [String:Any] {
        [ "service" : service.description,
          "rx" : rx.description,
          "tx" : tx.description
        ]
    }
    var characteristics : [CBUUID] { self.rx==self.tx ? [self.rx] : [self.rx,self.tx] }
    
    public var description: String {
        serialised.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
    }
    
    public static func ^(_ l : BLESerialTemplate,_ r : CBUUID) -> Bool { l.service==r }
    public static func ^(_ l : CBUUID,_ r : BLESerialTemplate) -> Bool { l==r.service }
    
    
}



