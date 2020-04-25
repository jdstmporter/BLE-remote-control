//
//  serial.swift
//  BT
//
//  Created by Julian Porter on 11/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//



import Foundation
import CoreBluetooth

public struct BLESerialTemplate {
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
    
    init?(_ key : String, values : [String:Any]) {
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
        [ "service" : service.uuidString,
          "rx" : rx.uuidString,
          "tx" : tx.uuidString
        ]
    }
    
}

public protocol BLESerialPort : BTCharacteristicDelegate, CustomStringConvertible {
    
    var service : BTService { get }
    var rx : BTCharacteristic { get }
    var tx : BTCharacteristic { get }
    var delegate : BLESerialDevicesDelegate? { get set }
    
    init?(peripheral : BTPeripheral,template : BLESerialTemplate)
    init?(_ service : BTService,rxtx : CBUUID)
    
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
    
    public var readable : Bool { return self.rx.readable }
    public var writeable : Bool { return self.tx.writeable }
    
    public func write(_ data : Data) { self.tx.write(data) }
    public func read() { self.rx.read() }
    public func notify(_ on: Bool) { self.rx.notify(on) }
    
    public var description: String { return "Serial port on device \(deviceID) [\(deviceName ?? "")] using RX \(rx.identifier) RTX \(tx.identifier)" }
    
    
}

public class BLEBaseSerial : BLESerialPort {
    
    public private(set) var service : BTService
  
    private var characteristic : BTCharacteristic
    public var delegate : BLESerialDevicesDelegate?
    
    public var rx : BTCharacteristic { characteristic }
    public var tx : BTCharacteristic { characteristic }
    
    public required init?(peripheral : BTPeripheral,template : BLESerialTemplate) {
        guard template.rx==template.tx,
            let service = peripheral[template.service],
            let c = service[template.rx] else { return nil }
        self.service=service
        self.characteristic=c
        self.characteristic.delegate=self
    }
    
    required public init?(_ service : BTService,rxtx : CBUUID = CBUUID(string: "FFE1")) {
        self.service = service
        guard let c = service[rxtx] else { return nil }
        self.characteristic = c
        self.characteristic.delegate = self
    }
    deinit {
        self.characteristic.delegate=nil
    }
    
    
    
    public func receivedValue(_ d: Data) {
        SysLog.info("Read : \(d)")
    }
    public func didConnect() {}
    public func didDisconnect() {}
    
    
}

