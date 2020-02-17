//
//  main.swift
//  BT
//
//  Created by Julian Porter on 06/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

var scanner : BTCentral!

func callback() {
    DispatchQueue.global(qos: .background).async {
        print("Starting scanner")
        scanner.start()
        print("Starting scanning")
        scanner.scan()
    }
}

scanner = BTCentral(onReady: callback );




