//
//  EnumeratorController.swift
//  BTApp
//
//  Created by Julian Porter on 16/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa




class EnumeratorController : NSViewController, NSTableViewDelegate, NSTableViewDataSource, BTPeripheralManagerDelegate {
    public static let id = NSUserInterfaceItemIdentifier(rawValue: "__Enumerator_row")
    
    

    @IBOutlet weak var systemStatus: NSImageView!
    @IBOutlet weak var table: NSTableView!
    @IBOutlet weak var scanButton: NSButton!
    private var bt = BTSystemManager()
    private var devs = SortableSet<BTPeripheral>()
    
    override func viewDidLoad() {
        bt.delegate=self
        guard let nib = NSNib(nibNamed: NSNib.Name("PeripheralRow"),bundle: nil) else { return }
        table.register(nib, forIdentifier: EnumeratorController.id)
    }
    
    override func viewDidAppear() {
        //bt.startScan()
    }
    override func viewWillDisappear() {
        //bt.stopScan()
    }
    
    
    @IBAction func onClick(_ sender: Any) {
    }
    
    @IBAction func scanAction(_ sender: NSButton) {
        switch sender.state {
        case .on:
            bt.startScan()
        case .off:
            bt.stopScan()
        default:
            break
        }
    }
    
    private func set(button b: Bool) {
        DispatchQueue.main.async {
            self.scanButton.isEnabled = b
            self.scanButton.state = .off
            let name = b ? NSImage.statusAvailableName : NSImage.statusUnavailableName
            self.systemStatus.image=NSImage(imageLiteralResourceName: name)
        }
    }
    
    
    
    func create(peripheral: BTPeripheral) {
        devs.add(peripheral)
        DispatchQueue.main.async { self.table.reloadData() }
    }
    
    func remove(peripheral: BTPeripheral) {
        devs.removeValue(peripheral)
        DispatchQueue.main.async { self.table.reloadData() }
    }
    
    func update(peripheral: BTPeripheral) {
        DispatchQueue.main.async { self.table.reloadData() }
    }
    
    func systemStateChanged(alive: Bool) {
        if alive { set(button: true) }
        else {
            bt.stopScan()
            set(button: false)
        }
    }
    
    // NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int { devs.count }
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard 0 <= row, row < devs.count else { return nil }
        return devs[row]
        
    }
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let dev = self.tableView(table,objectValueFor: nil,row: row) as? BTPeripheral else { return nil }
        var item = table.makeView(withIdentifier: EnumeratorController.id, owner: self) as? PeripheralRowView
        if item==nil { item = PeripheralRowView(frame: rowSize) }
        item?.peripheral=dev
        item?.touch()
        return item
    }
    
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { 160.0 }
    public func tableView(_ tableView: NSTableView, widthOfRow row: Int) -> CGFloat { table.bounds.width }
    
    private var rowSize : NSRect { NSRect(x: 0, y: 0, width: table.bounds.width, height: 160) }
 
    
}
