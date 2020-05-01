//
//  templates.swift
//  BTApp
//
//  Created by Julian Porter on 01/05/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreBluetooth

public class TemplateManager : Sequence {
    public typealias Element = BLESerialTemplate
    public typealias Iterator = Array<Element>.Iterator
    
    public private(set) var templates : [BLESerialTemplate] = []
    
    public init() {
       templates.removeAll()
        templates=[BLESerialTemplate(service: CBUUID(string:"FFE0"), rxtx: CBUUID(string:"FFE1"), name: "Ble-Nano")]
    }
    
    public func makeIterator() -> Array<Element>.Iterator { templates.makeIterator() }
    public var count : Int { templates.count }
    
    public func match(_ service : BTService) -> BLESerialTemplate? {
        templates.first { $0.service == service.identifier }
    }
}
public let Templates = TemplateManager()
