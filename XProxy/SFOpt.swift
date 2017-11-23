//
//  SFOpt.swift
//  Surf
//
//  Created by 孔祥波 on 30/11/2016.
//  Copyright © 2016 yarshure. All rights reserved.
//

import Foundation


struct SFOpt {
    static var TCPTimeout:Double = 30
    static var  longConnect = ["userstream.twitter.com","api.twitter.com"]
    static var HTTPVeryTimeout:Double = 15.0
    static var HTTPSTimeout:Double = 30.0
    static var HTTPNoHeaderTimeout:Double = 30
    static var HTTPLongConnect:Double = 30
    
    static func shouldKepp(host:String) ->Bool {
        let r = longConnect.filter { (h) -> Bool in
            return  host.hasPrefix(h)
        }
        if !r.isEmpty{
            return true
        }else {
            return false
        }
    }
}
