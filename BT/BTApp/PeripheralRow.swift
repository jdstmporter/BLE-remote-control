//
//  PeripheralRow.swift
//  BTApp
//
//  Created by Julian Porter on 17/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa
import CoreBluetooth

extension NSControl.StateValue {
    public init(_ b : Bool?) {
        if let bb = b { self = bb ? .on : .off }
        else { self = .mixed }
    }
}

infix operator =? : ComparisonPrecedence
protocol NullEquatable where Self : Equatable {
    static func =?(_ l : Self, _ r : Self?) -> Bool?
    static func =?(_ l : Self?, _ r : Self) -> Bool?
}
extension NullEquatable {
    public static func =?(_ l : Self, _ r : Self?) -> Bool? {
        guard let rr=r else { return nil }
        return l==rr
    }
    public static func =?(_ l : Self?, _ r : Self) -> Bool? {
        guard let ll=l else { return nil }
        return ll==r
    }
}
extension CBUUID : NullEquatable {}

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
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    private var matchedServices : [CBUUID] = []
    public var delegate : PeripheralRowViewDelegate? = nil
    public var peripheral : BTPeripheral? = nil { didSet { self.touch() } }
    public var isFavourite : Bool { favourite?.state == .on }
    
    
    
    public func touch(isFavourite : Bool = false) {
        guard let p=self.peripheral else { return }
        self.matchedServices = p.matchedUUIDs
        DispatchQueue.main.async {
            self.name?.stringValue = p.localName ?? ""
            self.uuid?.stringValue = p.identifier.uuidString
            self.rssi?.doubleValue = p.rssi
            self.favourite?.state = NSControl.StateValue(isFavourite)
            self.services.reloadData()
            
            if p.isConnected {
                self.spinner.stopAnimation(nil)
                self.spinner.isHidden=true
            }
            else {
                self.spinner.isHidden=false
                self.spinner.startAnimation(nil)
            }
        }
    }
    
    public func wouldChange(_ pp : BTPeripheral) -> Bool {
        guard let p = self.peripheral else { return true }
        if p.localName != pp.localName { return true }
        if p.identifier != pp.identifier { return true }
        if p.rssi != pp.rssi { return true }
        return false
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
            let matched = self.matchedServices.contains(id)
            let st = NSControl.StateValue(matched)
            if let view = services.makeView(withIdentifier: PeripheralRowView.sw, owner: self) as? OnOffView {
                view.state = st
                return view
            }
            else {
                let view = OnOffView(state: st)
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
