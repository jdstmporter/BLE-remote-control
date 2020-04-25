//
//  PeripheralRow.swift
//  BTApp
//
//  Created by Julian Porter on 17/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa
import CoreBluetooth

protocol PeripheralRowViewDelegate {
    func favouriteChanged(device: UUID,value: Bool)
}

class PeripheralRowView : NSTableCellView, NSTableViewDelegate, NSTableViewDataSource {
    
    public static let id = NSUserInterfaceItemIdentifier(rawValue: "__Enumerator_PeripheralRowView")
    public static let sw = NSUserInterfaceItemIdentifier(rawValue: "__Enumerator_PeripheralRowViewSwitch")
    
    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var uuid: NSTextField!
    @IBOutlet weak var rssi: NSTextField!
    @IBOutlet weak var services: NSTableView!
    @IBOutlet weak var favourite: NSButton!
    
    public var delegate : PeripheralRowViewDelegate? = nil
    public var peripheral : BTPeripheral? = nil { didSet { self.touch() } }
    public var isFavourite : Bool { favourite?.state == .on }
    
    public func touch(_ isFavourite : Bool = false) {
        guard let p=self.peripheral else { return }
        DispatchQueue.main.async {
            self.name?.stringValue = p.localName ?? ""
            self.uuid?.stringValue = p.identifier.uuidString
            self.rssi?.doubleValue = p.rssi
            self.favourite?.state = isFavourite ? .on : .off
            self.services.reloadData()
        }
    }
    
    @IBAction func favouriteAction(_ sender: NSButton) {
        guard let p=peripheral else { return }
        SysLog.info("Clicked button: \(sender.state) is FAV \(isFavourite)")
        delegate?.favouriteChanged(device: p.identifier, value: isFavourite)
    }
    
    public var count : Int { peripheral?.serviceIDs.count ?? 0 }
    
    public func numberOfRows(in tableView: NSTableView) -> Int { count }
    
    
    

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let col = tableColumn?.title, 0 <= row, row<count, let id = peripheral?.serviceIDs[row] else { return nil }
        if col=="UUID" {
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
        else if col=="Template" {
            if let view = services.makeView(withIdentifier: PeripheralRowView.sw, owner: self) as? OnOffView {
                view.state = .on
                return view
            }
            else {
                let view = OnOffView(state: .on) 
                view.identifier=PeripheralRowView.sw
                return view
            }
        }
        else { return nil }
    }
    
    
    
    
    override func  draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    
    
    
}
