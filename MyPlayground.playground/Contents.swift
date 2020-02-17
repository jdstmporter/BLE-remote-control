import Cocoa
import CoreBluetooth

var str = "Hello, playground"

extension Data {
    var hex : String {
        return self.withUnsafeBytes { ptr in
            let arr = ptr.bindMemory(to: UInt8.self)
            return arr.map { String(format:"%02x",$0) }.joined(separator:"")
        }
    }
    var str : String? { return String(data: self, encoding: .utf8) }
    
    
    
    
}

extension Array where Element==UInt8 {
    init?(hex : String) {
        guard let d=hex.asHex else { return nil }
        self = d
    }
    
    var ascii : String? { return String(bytes: self, encoding: .ascii) }
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




let ss="abcdef"
let a = ss.utf8CString
let b : [UInt8] = a.map { numericCast($0) }

extension UInt8 {
    var hex : String { return String(format:"%02x",self) }
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
    
    public enum Command: UInt8, CaseIterable {
        
        case ERROR = 0x00
        
        case Reset = 0x80
        case Start = 0x81
        case Stop  = 0x82
        case Identify = 0x90
        case Identity = 0x91
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
do {
    let mx = Message(command: .Identify, body: [1,2,3,4])
    mx.bytes
    print(mx)
    let bxx=try Message(packet: mx.bytes)
    bxx.command
    bxx.body
    print(bxx)
}
catch let e { print(e) }







