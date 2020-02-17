//
//  uuencode.swift
//  BT
//
//  Created by Julian Porter on 14/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

public enum Command: UInt8, CaseIterable {
    
    case ERROR = 0x00
    
    case Reset = 0x80
    case Start = 0x81
    case Stop  = 0x82
    
    case Identity = 0x90
    case Sequence = 0xa0
    
    public init(_ raw : UInt8) {
        self=Command.init(rawValue: raw) ?? .ERROR
    }
    public var isValid : Bool { return self != .ERROR }
    public static var values : [UInt8] { return allCases.map { $0.rawValue }}
    public static func isValid(_ value : UInt8) -> Bool { return Command(value).isValid }
    
    public var byte : UInt8 { return rawValue }
    public var name : String { return "\(self)".uppercased() }
    
    
}

public class Message : CustomStringConvertible {
    public enum Failure : Error {
        case BadPacket
        case BadContent
        case NoHeader
        case InvalidCommand
        case InvalidLength
        case NoFooter
    }
    
    public static let HEADER : UInt8 = 0xc0
    public static let FOOTER : UInt8 = 0xcf
    
    public private(set) var command : Command
    public private(set) var body : [UInt8]
    
    public init(command: Command, body: [UInt8] = []) {
        self.command = command
        self.body = body
    }
    public init(packet: [UInt8]) throws {
        if packet.count < 4 { throw Failure.BadPacket }
        guard packet.first==Message.HEADER else { throw Failure.NoHeader }
        guard packet.last==Message.FOOTER else { throw Failure.NoFooter }
        self.command = Command(packet[1])
        let length = packet[2] & 0x7f
        guard length+4 == packet.count else { throw Failure.InvalidLength }
        guard let s = packet[3...].dropLast().ascii else { throw Failure.BadContent }
        guard let body = s.asHex else { throw Failure.BadContent }
        self.body=body
    }
    
    public convenience init(packet : Data) throws {
        var b=Array<UInt8>(repeating: 0, count: packet.count)
        _ = b.withUnsafeMutableBufferPointer { packet.copyBytes(to: $0) }
        try self.init(packet: b)
    }
    
   
    public var bytes : [UInt8] {
        let s : String = self.body.map { $0.hex }.joined(separator : "")
        let b : [UInt8] = s.utf8CString.map { numericCast($0) }.dropLast()
        let l : UInt8 = numericCast(b.count & 0x7f) | 0x80
        var out = [Message.HEADER,self.command.byte,l]
        out.append(contentsOf: b)
        out.append(Message.FOOTER)
        return out
    }
    public var data : Data { return Data(self.bytes) }
    
    public var description: String {
        let b = body.map { $0.hex }.joined(separator: ",")
        return "\(command.name) : [\(b)]"
    }
    
}
