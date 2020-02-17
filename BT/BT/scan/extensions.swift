//
//  extensions.swift
//  BT
//
//  Created by Julian Porter on 09/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

extension DispatchTime {
    static func after(_ i : DispatchTimeInterval) -> DispatchTime {
        return DispatchTime.now() + i
    }
    static func after(milliseconds ms: Int) -> DispatchTime {
        return DispatchTime.after(DispatchTimeInterval.milliseconds(ms))
    }
}

extension String {
    func split(into n : Int) -> [String] {
        let nChunks = count / n
        return (0..<nChunks).compactMap { idx in
            guard let range = Range<String.Index>.init(NSRange(location: n*idx, length: n), in: self) else { return nil }
            return String(self[range])
        }
    }
    
    var asHex : [UInt8]? {
        let parts = self.split(into: 2)
        let bytes : [UInt8] = parts.compactMap { UInt8($0,radix: 16) }
        if bytes.count < parts.count { return nil }
        return bytes
    }
    
    
}

extension UInt8 {
    var hex : String { return String(format:"%02x",self) }

}

extension Array where Element==UInt8 {
    init?(hex : String) {
        guard let d=hex.asHex else { return nil }
        self = d
    }
    
    var ascii : String? { return String(bytes: self, encoding: .ascii) }
}




extension Data {
    var hex : String {
        return self.withUnsafeBytes { ptr in
            let arr = ptr.bindMemory(to: UInt8.self)
            return arr.map { String(format:"%02x",$0) }.joined(separator:"")
        }
    }
    var str : String? { return String(data: self, encoding: .utf8) }
    
    init?(hex: String) {
        guard let d=hex.asHex else { return nil }
        self=Data(d)
    }
    
    
    
}

