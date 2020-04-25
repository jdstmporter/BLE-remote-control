//
//  logging.swift
//  BTApp
//
//  Created by Julian Porter on 18/04/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import os


extension OSLogType : CaseIterable, Comparable, Hashable, CustomStringConvertible {
    public typealias AllCases = Array<OSLogType>
    public static let allCases : AllCases = [ .debug, .info, .error, .fault ]
    public static let names : [OSLogType:String] = [
        .debug : "debug",
        .info : "info",
        .error : "error",
        .fault : "fault"
    ]
    public init?(_ n : String) {
        guard let idx = (OSLogType.names.first { $0.value==n })?.key else { return nil }
        self=idx
    }
    
    public var index : Int { OSLogType.allCases.firstIndex(of: self) ?? -1 }
    public static func==(_ l : OSLogType,_ r : OSLogType) -> Bool { l.index == r.index }
    public static func<(_ l : OSLogType,_ r : OSLogType) -> Bool { l.index < r.index }
    
    public var description: String { OSLogType.names[self] ?? "-" }
}

@dynamicCallable
@dynamicMemberLookup
public class _SysLog {
    public typealias Logger = (CustomStringConvertible) -> ()
    
    private var level : OSLogType
    private var log : OSLog
    
    
    public init(_ level : OSLogType = .default,subsystem: String = "org.porternet.bt") {
        self.level=level
        self.log=OSLog(subsystem: subsystem, category: .pointsOfInterest)
    }
    
    internal func log(_ level : OSLogType,_ message: String) {
        guard level >= self.level, self.log.isEnabled(type: level) else { return }
        os_log(level, log: self.log, "[%@] %@", level.description,message)
    }
    
    public subscript(dynamicMember n: String) -> Logger {
        guard let idx = OSLogType(n) else { return { _ in () } }
        return { self.log(idx,$0.description) }
    }
    public func dynamicallyCall(withArguments level: [OSLogType]) {
        self.level=level.first ?? .default
    }
}

#if LOG_DEBUG
public let SysLog = _SysLog(.debug)
#elseif LOG_INFO
public let SysLog = _SysLog(.info)
#else
public let SysLog = _SysLog(.error)
#endif
