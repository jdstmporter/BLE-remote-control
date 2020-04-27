//
//  onOffView.swift
//  BTApp
//
//  Created by Julian Porter on 27/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa

class OnOffView : NSImageView {
    
    private static let images : [NSControl.StateValue : NSImage] = [
        .on : NSImage(imageLiteralResourceName: NSImage.statusAvailableName),
        .mixed : NSImage(imageLiteralResourceName: NSImage.statusPartiallyAvailableName),
        .off : NSImage(imageLiteralResourceName: NSImage.statusUnavailableName)
    ]
    private static let noImage = NSImage(imageLiteralResourceName: NSImage.statusNoneName)
    
    private static func getImage(for state: NSControl.StateValue?) -> NSImage {
        var im : NSImage? = nil
        if let s=state { im = OnOffView.images[s] }
        return im ?? OnOffView.noImage
    }
    
    private var _state : NSControl.StateValue? = nil
    public var state : NSControl.StateValue? {
        get { _state }
        set {
            _state = newValue
            self.image = OnOffView.getImage(for: _state)
        }
    }
    
    public convenience init() { self.init(frame: NSRect()) }
    
    public init(state: NSControl.StateValue?) {
        super.init(frame: NSRect())
        self.state=state
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.state=nil
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.state=nil
    }
}

