//
//  serviceDelegate.swift
//  BT
//
//  Created by Julian Porter on 11/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public class ServiceCharacteristicSet {
    private var items = ListDict<CBUUID,ServiceCharacteristic>()
    
    public subscript(_ service: CBUUID) -> [ServiceCharacteristic] {
        get { return items[service] }
        set { items.append(service,newValue) }
    }
    

    public subscript(_ service: CBUUID, _ characteristic: CBUUID) -> ServiceCharacteristic? {
        let services=self[service]
        return services.filter { $0.characteristic == characteristic }.first
    }
}



public class BTServiceManager : BTBasicDelegate, BTServiceDelegate {
    public static let BTServiceDiscoveredEvent = Notification.Name("__BTServiceDiscoveredEvent_Name")
    public typealias Callback = ([CBUUID]) -> ()
    public enum State {
        case Waiting
        case Matching
        case Ready
    }
    private var service : BTService
    public private(set) var state : State
    
    public var delegate : BTPeripheralManagerDelegate?
    
    private var matched : Bool? = nil {
        didSet {
            if matched != oldValue {
                SysLog.debug("Have configured service \(service)")
                delegate?.update(peripheral: service.peripheral)
            }
        }
    }
    
    public init(_ service: BTService) {
        self.service=service
        self.state = .Waiting
        self.service.delegate=self
    }
    
    public func run() {
        var next = state
        switch state {
        case .Waiting:
            service.discoverCharacteristics()
            next = .Matching
        case .Ready:
            service.forEach { $0.read() }
        default:
            break
        }
        state = next
    }
    
    public var uuids : [CBUUID] { service.uuids }
    
    
    public func discoveredCharacteristics() {
        state = .Ready
        let notification=Notification(name: BTServiceManager.BTServiceDiscoveredEvent, object: nil, userInfo: ["service": service])
        NotificationCenter.default.post(notification)
        matched = service.matches()
        run()
    }
    
    public func updatedCharacteristic(_ characteristic: BTCharacteristic) {
        guard let v=characteristic.bytes else { return }
        SysLog.debug(">>>> Characteristic \(characteristic.identifier) on \(service.identifier) has discovered value")
        SysLog.debug(characteristic)
        characteristic.delegate?.receivedValue(v)
    }
    
    
}



