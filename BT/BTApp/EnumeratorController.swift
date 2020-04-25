//
//  EnumeratorController.swift
//  BTApp
//
//  Created by Julian Porter on 16/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa

extension Array where Element : Equatable {
    public mutating func remove(value: Element) {
        self=self.filter { $0 != value }
    }
    public func contains(_ test : (Element) -> Bool) -> Bool {
        nil != first(where : test)
    }
}


class EnumeratorController : NSViewController, NSTableViewDelegate, NSTableViewDataSource, BTPeripheralManagerDelegate, UserDataListener, PeripheralRowViewDelegate, NSComboBoxDataSource {
    public static let id = NSUserInterfaceItemIdentifier(rawValue: "__Enumerator_row")
    
    private enum ScanForChoice : CaseIterable {
        case All
        case Favourites
        
        
        public var name : String { "\(self)" }
        public var index : Int { ScanForChoice.allCases.firstIndex(of: self) ?? -1 }
        public init?(_ n : String) {
            guard let s = (ScanForChoice.allCases.first { n==$0.name }) else { return nil }
            self=s
        }
        public init?(_ n : Int) {
            guard n>=0, n<ScanForChoice.allCases.count else { return nil }
            self = ScanForChoice.allCases[n]
        }
    }
    

    @IBOutlet weak var scanFor: NSComboBox!
    @IBOutlet weak var systemStatus: NSImageView!
    @IBOutlet weak var table: NSTableView!
    @IBOutlet weak var scanButton: NSButton!
    private var bt = BTSystemManager()
    private var devs = SortableSet<BTPeripheral>()
    private var favourites : [UUID] = []
    
    
    public var id = UUID()
    
    
    private func loadFavourites() {
        guard let raw : [String] = UserData["favourites"] else { return }
        favourites = raw.compactMap { UUID(uuidString: $0) }
        SysLog.info("Loaded favourites: \(raw)")
    }
    
    override func viewDidLoad() {
        bt.delegate=self
        guard let nib = NSNib(nibNamed: NSNib.Name("PeripheralRow"),bundle: nil) else { return }
        table.register(nib, forIdentifier: EnumeratorController.id)
        loadFavourites()
        UserData.listen(self)
        
        scanning = .All
        
    }
    
    override func viewDidAppear() {
        //bt.startScan()
    }
    override func viewWillDisappear() {
        //bt.stopScan()
    }
    
    private var scanning : ScanForChoice {
        get { ScanForChoice(scanFor.indexOfSelectedItem) ?? .All }
        set { DispatchQueue.main.async { self.scanFor.selectItem(at: newValue.index) } }
    }
    
    
    @IBAction func scanForChange(_ sender: NSComboBox) {
        SysLog.info("Scan for state changed to \(scanning.name)")
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
    
    
    
    public func valuesChanged(keys: [String]) {
        guard keys.contains("favourites") else { return }
        loadFavourites()
        // reload the GUI
    }
    
    public func favouriteChanged(device: UUID, value: Bool) {
        // make sure that we have such a device, and that the 'new' value
        // for its favourite status is a change from what is currently
        // true (designed to avoid infinite recursion by pushing back
        // to cloud when nothing has changed)
        SysLog.info("Contains: \(devs.contains { $0.identifier == device }) ALREADY: \(favourites.contains(device)) NEW: \(value)")
        guard (devs.contains { $0.identifier == device }),
            favourites.contains(device) != value
            else { return }
        
        if value { favourites.append(device) }
        else { favourites.remove(value: device) }
        UserData["favourites"] = favourites.map { $0.uuidString }
        SysLog.info("Favs are now: \(favourites.map { $0.uuidString })")
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
        SysLog.info("Adding \(peripheral)")
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
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let dev = self.tableView(table,objectValueFor: nil,row: row) as? BTPeripheral else { return nil }
        var item = table.makeView(withIdentifier: EnumeratorController.id, owner: self) as? PeripheralRowView
        if item==nil { item = PeripheralRowView(frame: rowSize) }
        item?.delegate=self
        item?.peripheral=dev
        item?.touch(self.favourites.contains(dev.identifier))
        return item
    }
    
    
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { 160.0 }
    public func tableView(_ tableView: NSTableView, widthOfRow row: Int) -> CGFloat { table.bounds.width }
    
    private var rowSize : NSRect { NSRect(x: 0, y: 0, width: table.bounds.width, height: 160) }
 
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        true
    }
    func tableView(_ tableView: NSTableView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        true
    }
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        false
    }
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        
    }
    
    // combo box datasource methods
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        ScanForChoice(index)?.name
    }
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        ScanForChoice(string)?.index ?? NSNotFound
    }
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        ScanForChoice.allCases.count
    }
    
}
