//
//  central.swift
//  BT
//
//  Created by Julian Porter on 06/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth




public class BTCentral : NSObject, CBCentralManagerDelegate, Sequence {
    
    public typealias Element = BTPeripheral
    public typealias Iterator = Array<Element>.Iterator
    
    private static var _central : BTCentral!
    public static var shared : BTCentral {
        if _central==nil { _central=BTCentral() }
        return _central!
    }
    
    public enum BLE {
        case Unavailable
        case Illegal
        case Enabled
        case Unknown
    }
    
    //private var semaphore : DispatchSemaphore? = nil
    private var central : CBCentralManager!
    public var delegate : BTPeripheralManagerDelegate?
    public private(set) var state : CBManagerState
    public var alive : Bool { return state == .poweredOn }
    private var ble : BLE = .Unknown
    public private(set) var peripherals : OrderedDictionary<UUID,BTPeripheral>
    
    public override init() {
        state = .unknown
        peripherals = OrderedDictionary<UUID,BTPeripheral>()
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    public private(set) subscript(_ uuid : UUID) -> BTPeripheral? {
        get { return self.peripherals[uuid] }
        set {
            if let v=newValue { self.peripherals[uuid]=v }
        }
    }
    public subscript(_ p : CBPeripheral) -> BTPeripheral? { return self.peripherals[p.identifier] }
    public var count : Int { return peripherals.count }
    public func makeIterator() -> Iterator { self.peripherals.values.makeIterator() }
    public func contains(_ id : UUID) -> Bool { peripherals[id] != nil }
   
    public var scanning : Bool { self.central.isScanning }
    public func scan(services : [CBUUID]? = nil) {
        SysLog.info("******** trying to scan with \(services?.description ?? "nil")")
            if(!self.central.isScanning) {
                self.central.scanForPeripherals(withServices: services, options: nil)
            }
        
    }
    public func stopScan() {
            if self.central.isScanning {
                self.central.stopScan()
            }
        
    }
    public func connect(_ d : BTPeripheral) {
        central.connect(d.device, options: nil)
    }
    
    
    
    
    // delegate methods
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state=central.state
        switch state {
        case .poweredOn:
            //semaphore?.signal()
            SysLog.info("Powered on")
            DispatchQueue.global(qos: .background).async {
                //self.scan()
            }
        case .poweredOff:
            DispatchQueue.global(qos: .background).async {
                self.stopScan()
            }
            peripherals.removeAll()
            SysLog.info("Powered off")
        case .resetting:
            SysLog.info("Resetting")
        case .unknown:
            SysLog.info("Unknown state")
        case .unsupported:
            ble = .Unavailable
            SysLog.info("BLE unavailable")
        case .unauthorized:
            switch central.authorization {
            case .restricted:
                SysLog.error("Bluetooth is restricted on this device")
            case .denied:
                SysLog.error("The application is not authorized to use the Bluetooth Low Energy role")
            default:
                SysLog.fault("Something went wrong. Cleaning up cbManager")
            }
            ble = .Illegal
        default:
            SysLog.error("Error state \(central.state)")
            
        }
        SysLog.info("Central manager has changed state: \(state)")
        //delegate?.changedState()
        delegate?.systemStateChanged(alive: BTCentral.shared.alive)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let p=self[peripheral] {
            p.hasConnected()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let p=self[peripheral] {
            p.hasFailedToConnect()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let p=self[peripheral] {
            p.hasDisconnected()
        }
    }
    
    private static let queue = DispatchQueue(label: "BTEnumerateQueue", qos: .background)
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData ads: [String : Any], rssi RSSI: NSNumber) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(milliseconds: 100))  {
            let identifier=peripheral.identifier
            let new = self[identifier] == nil
            if new {
                let p=BTPeripheral(peripheral,advertisementData: ads, rssi: Double(truncating: RSSI))
                p.delegate=self.delegate
                self[p.identifier]=p
                if new {
                    guard let pp = self[p.identifier] else { return }
                        self.delegate?.create(peripheral: pp)
                        SysLog.info("Connecting \(pp)")
                        pp.connect()
                }
            }

        }
    }
    
    
}
