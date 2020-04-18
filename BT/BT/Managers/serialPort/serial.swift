//
//  serial.swift
//  BT
//
//  Created by Julian Porter on 11/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//



import Foundation
import CoreBluetooth

public protocol BLESerialPort : BTCharacteristicDelegate, CustomStringConvertible {
    
    var service : BTService { get }
    var characteristic : BTCharacteristic { get }
    var delegate : BLESerialDevicesDelegate? { get set }
    
    init?(_ service : BTService,uuid : CBUUID)
    var connected : Bool { get }
    var device : BTPeripheral { get }
    var deviceName : String? { get }
    var readable : Bool { get }
    var writeable : Bool { get }
    
    func write(_ : Data)
    func read()
    func notify(_ : Bool)
}

public typealias BLESerialDeviceMaker = (BTService,CBUUID) -> BLESerialPort?

extension BLESerialPort {
    
    public var connected : Bool { return self.service.connected }
    
    public var device : BTPeripheral { return self.service.peripheral }
    public var deviceID : UUID { return self.device.identifier }
    public var deviceName : String? { return self.device.localName }
    
    public var readable : Bool { return self.characteristic.readable }
    public var writeable : Bool { return self.characteristic.writeable }
    
    public func write(_ data : Data) { self.characteristic.write(data) }
    public func read() { self.characteristic.read() }
    public func notify(_ on: Bool) { self.characteristic.notify(on) }
    
    public var description: String { return "Serial port on device \(deviceID) [\(deviceName ?? "")] using characteristic \(characteristic.identifier)" }
    
    
}

public class BLEBaseSerial : BLESerialPort {
    
    public private(set) var service : BTService
    public private(set) var characteristic : BTCharacteristic
    public var delegate : BLESerialDevicesDelegate?
    
    public required init?(_ service : BTService,uuid : CBUUID = CBUUID(string: "FFE1")) {
        self.service = service
        guard let c = service[uuid] else { return nil }
        self.characteristic = c
        self.characteristic.delegate = self
    }
    deinit {
        self.characteristic.delegate=nil
    }
    
    
    
    public func receivedValue(_ d: Data) {
        SysLog.DebugLog.info("Read : \(d)")
    }
    public func didConnect() {}
    public func didDisconnect() {}
    
    
}

