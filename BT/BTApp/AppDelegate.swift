//
//  AppDelegate.swift
//  BTApp
//
//  Created by Julian Porter on 06/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa
import CoreBluetooth

public class Delegate : BLESerialDevicesDelegate {
    
    
    public func discoveredSerialPort(_ s: BLESerialPort) {
        SysLog.info("++++++ \(s)")
        s.notify(true)
    }
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    var ser : BLESerialDevices<BLEBaseSerial>!
    
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        SysLog(.info)
        UserDataManager.shared.start()
        //ser = BLESerialDevices(service: CBUUID(string: "FFE0"),characteristic: CBUUID(string: "FFE1"))
        //ser.delegate=Delegate()
        //ser.start()
    }
    
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        UserDataManager.shared.stop()
    }


}

