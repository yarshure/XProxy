//
//  SFIPAddr.swift
//  Surf
//
//  Created by yarshure on 15/12/25.
//  Copyright © 2015年 yarshure. All rights reserved.
//

import Foundation


public struct IPAddr {
    public var ip:UInt32 = 0
    public var port:UInt16 = 0
    public init(i:UInt32,p:UInt16){
        ip = i
        port = p
    }
    func ipString() ->String{
        let a = (ip & 0xFF)
        let b = (ip >> 8 & 0xFF)
        let c = (ip >> 16 & 0xFF)
        let d = (ip >> 24 & 0xFF)
        return "\(a)." + "\(b)." + "\(c)." + "\(d)"
    }
    func p () ->UInt16 {
        return port.byteSwapped
    }
    mutating func ipFromString(_ str:String) ->UInt32{
        ip =  inet_addr(str.cString(using: String.Encoding.utf8)!)
        return ip
    }
    public func equal(_ addr:IPAddr)->Bool{
        if self.ip == addr.ip && self.port == addr.port {
            return true
        }
        return false
    }
   
}
