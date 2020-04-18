//
//  PeripheralRow.swift
//  BTApp
//
//  Created by Julian Porter on 17/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa
import CoreBluetooth

class PeripheralRowView : NSTableRowView, NSTableViewDelegate, NSTableViewDataSource {
    
    public static let id = NSUserInterfaceItemIdentifier(rawValue: "__Enumerator_PeripheralRowView")
    
    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var uuid: NSTextField!
    @IBOutlet weak var rssi: NSTextField!
    @IBOutlet weak var services: NSTableView!
    
    public var peripheral : BTPeripheral? = nil { didSet { self.touch() } }
    
    public func touch() {
        guard let p=self.peripheral else { return }
        DispatchQueue.main.async {
            self.name?.stringValue = p.localName ?? ""
            self.uuid?.stringValue = p.identifier.uuidString
            self.rssi?.doubleValue = p.rssi
            self.services.reloadData()
        }
    }
    
    public var count : Int { peripheral?.serviceIDs.count ?? 0 }
    
    public func numberOfRows(in tableView: NSTableView) -> Int { count }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard 0 <= row, row<count else { return nil }
        return peripheral?.serviceIDs[row]
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let id = self.tableView(tableView,objectValueFor: tableColumn, row: row) as? CBUUID else { return nil }
        if let view = services.makeView(withIdentifier: PeripheralRowView.id, owner: self) as? NSTextField {
            view.stringValue = id.description
            return view
        }
        else {
            let view = NSTextField.init(labelWithString: id.description)
            view.identifier=PeripheralRowView.id
            return view
        }
    }
    
    override func drawBackground(in dirtyRect: NSRect) {
        NSColor.black.setFill()
        dirtyRect.fill()
    }
    
    
}
