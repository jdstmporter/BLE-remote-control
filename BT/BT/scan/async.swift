//
//  async.swift
//  BT
//
//  Created by Julian Porter on 07/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

public class Wait {
    public typealias Action = () -> ()
    
    private var action : Action?
    
    public init(_ action : Action) {
        self.action=action
    }
    public func fire() {
        DispatchQueue.global(qos: .background) .sync {
            self.action?()
            self.action=nil
        }
    }
    
}
