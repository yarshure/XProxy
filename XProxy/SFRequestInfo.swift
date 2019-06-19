//
//  SFRequest.swift
//  Surf
//
//  Created by yarshure on 16/1/15.
//  Copyright © 2016年 yarshure. All rights reserved.
//

import Foundation
import Xcon
import XRuler

let KEEP_APPLE_TCP = true
public class SFRequestInfo {
    //mitm config will add to XRuler
    public var mitm:Bool = false
    
    public var mode:SFConnectionMode = .TCP //tcp http https
    public var url:String = ""
    //var requestId:Int = 0
    public var app = "" //user-agent
    public var interfaceCell:Int64 = 0
    public var localIPaddress:String = ""
    public var remoteIPaddress:String = ""
    public var sTime:Date// = Date.init(timeIntervalSince1970: 0)
    public var estTime = Date()
    public var status:SFConnectionStatus = .Start
    public var closereason:SFConnectionCompleteReason = .noError
    public var delay_start:Double = 0.0
//    var req:NSMutableData = NSMutableData() //req header
//    var resp:NSMutableData = NSMutableData() //respond header
    public var started:Bool = false
    public var reqHeader:SFHTTPRequestHeader?
    public var respHeader:SFHTTPResponseHeader?
    public var respReadFinish:Bool = false
    //var policy:SFPolicy = .Direct
    public var recvSpped:UInt = 0
    public var waitingRule:Bool = false //Rule 结果没返回需要等待DNS request
    public var limit:Bool = false
    public var ruleStartTime:Date = Date()
   
    public var proxy:SFProxy?
    public var rule:SFRuler = SFRuler()
    public var inComingTime:Date = Date()
    
    public var traffice:SFTraffic = SFTraffic()
    
    public var speedtraffice:SFTraffic = SFTraffic()//用于cache 速度 traffice
    
    public var activeTime = Date() //last active time
    public var eTime = Date.init(timeIntervalSince1970: 0) //send time
    
    public var reqID:UInt
    public var subID:UInt
    public var lport:UInt16 = 0//lsof -n -i tcp:ip@port
    public var dbID:UInt = 0
    //var pcb_closed = false 减少不必要的状态机
    // set client not closed
    public var client_closed = false // 0 pcb alive ,1 dead
    // set SOCKS not up, not closed
    public var socks_up = false
    public var socks_closed = false

    #if LOGGER
    public var sendData:Data = Data()
    public var recvData:Data = Data()
    #endif
    public init(rID:UInt,sID:UInt = 0) {
        reqID = rID
        subID = sID
        sTime = Date()
    }
    public func isSubReq() ->Bool {
        if subID == 0 {
            return true
        }else {
            return false
        }
    }
    public var host:String {
        var result = ""
        if let r = reqHeader {
            if !r.ipAddressV4.isEmpty {
                result = r.ipAddressV4
            }else {
                result =  r.Host
            }
            
            
        }else {
            result = remoteIPaddress
        }
        return result
    }
    public var port:Int{
        if let r  = reqHeader{
            return r.Port
        }
        return 80
    }

    public func updateInterface(_ data:Data){
        
    }
    public func updateSpeed(_ c:UInt, stat:Bool)  {
        if c > 0 {
            if stat{
                //traffice.addRx(Int(c))
            }
            
            let now = Date()
            let ts = now.timeIntervalSince(activeTime)
            let msec = UInt(ts*1000) //ms
            if msec == 0 {
                recvSpped = c
            }else {
                recvSpped = c / msec
            }
            
            if recvSpped > XProxy.LimitSpeedSimgle {
                limit = true
            }else {
                limit = false
            }
//            #if DEBUG
//           //XProxy.log("\(url) speed: \(msec)/\(recvSpped) ms \n",level:.Trace)
//            #endif
            
        }
    }
    public var ruleTiming:TimeInterval {
        get{
            return Date().timeIntervalSince(ruleStartTime)
        }
    }
    public var connectionTiming:TimeInterval {
        get {

            if estTime.timeIntervalSince(sTime) < 0.0 {
                return 0

            }
            return estTime.timeIntervalSince(sTime)
        }
        set(newT) {
            estTime = Date.init(timeInterval: newT, since: sTime)
            //self.connectionTiming = newT
        }
    }
    public var transferTiming:TimeInterval {
        get {

            if activeTime.timeIntervalSince(estTime) < 0.0 {
                return 0

            }
            return activeTime.timeIntervalSince(estTime)
        }
        set (newT){
            activeTime = Date.init(timeInterval: newT, since: estTime)
            //self.transferTiming = newT
        }
    }
    public var idleTimeing:TimeInterval {
        get {
            
            let now = Date()
            return now.timeIntervalSince(activeTime)
        }
    }
    public var workTimeing:String {
        get {
            let now = Date()
            let ts =  now.timeIntervalSince(sTime)
            return String(format: "Start: %.2f ms", ts*1000)
        }
    }
    public func  shouldCloseClient() ->Bool {
        var close = true
//        return false
        if KEEP_APPLE_TCP {
            if mode == .TCP {
                if url.hasPrefix("17."){
                    close = false
                    
                }
            }else {
                if url.range(of: "apple.com") != nil{
                    close = false
                    
                }
            }
 
        }
//        if connectionTiming <= 0 || transferTiming <= 0{
//            close = false
//        }
//        NSLog("%@ connectionTiming %.02f transferTiming %.02f",url, connectionTiming,transferTiming)
        return close
    }

    public var runing:TimeInterval {
        get {
            return eTime.timeIntervalSince(sTime)
        }
    }
    public func respObj() -> [String:AnyObject] {
        var r :[String:AnyObject] = [:]
        r["mode"] = mode.description as AnyObject?
        r["url"] = url as AnyObject?
        r["app"] = app as AnyObject?
        
        r["start"] = NSNumber.init(value: sTime.timeIntervalSince1970)
        r["status"] = status.description as AnyObject?
        r["closereason"] = closereason.description as AnyObject?
        if mode != .TCP {
            if let req = reqHeader {
                r["reqHeader"] =  req.headerString(nil) as AnyObject?
            }
            if let resp = respHeader {
                r["respHeader"] = resp.headerString( nil) as AnyObject?
            }
            
        }
        r["reqID"] = NSNumber.init(value: reqID)
        r["subID"] = NSNumber.init(value: subID)
        //r["proxyName"]  = rule.proxyName
        //r["Policy"] = policy.description
        //r["name"] = rule.name
        //r["type"] = NSNumber.init(int: Int32(rule.type.rawValue))
        //r["ruleTime"] = NSNumber.init(double: ruleTime)
        r["Est"] = NSNumber.init(value: connectionTiming)
        
        r["transferTiming"] = NSNumber.init(value:transferTiming)
        //print("############\(rule.resp())")
        r["Rule"] = rule.resp() as AnyObject?
        
        
        r["Traffic"] = traffice.resp() as AnyObject?
//        r["tx"] = NSNumber.init(unsignedInteger:traffice.tx)
//        r["rx"] = NSNumber.init(unsignedInteger: traffice.rx)
        
        r["port"] = NSNumber.init(value: lport)
        r["end"] = NSNumber.init(value: eTime.timeIntervalSince1970)
        r["interface"] = NSNumber.init(value:interfaceCell)
        r["localIP"] = localIPaddress as AnyObject?
        r["remoteIP"] = remoteIPaddress as AnyObject?
        return r
    }
//    public func map(_ j:JSON){
//        
//        self.mode = SFConnectionMode(rawValue:j["mode"].stringValue)!
//        self.url = j["url"].stringValue
//        self.app = j["app"].stringValue
//        self.lport = j["port"].uInt16Value
//        var  s = j["start"]
//        self.sTime = Date.init(timeIntervalSince1970: s.doubleValue)
//        self.status = SFConnectionStatus(rawValue:j["status"].stringValue)!
//        let reason = j["closereason"].intValue
//        self.closereason = SFConnectionCompleteReason(rawValue:reason)!
//        
//        if mode != .TCP {
//            var head = j["respHeader"]
//            if head.error == nil {
//                let str = head.stringValue
//                if let d = str.data(using: String.Encoding.utf8) {
//                    if let h = SFHTTPResponseHeader.init(data: d) {
//                        self.respHeader = h
//                    }
//                    
//                    
//                }
//            }
//            
//            head = j["reqHeader"]
//            if head.error == nil {
//                let str = head.stringValue
//                if let d = str.data(using: String.Encoding.utf8) {
//                    if let h = SFHTTPRequestHeader.init(data: d) {
//                         self.reqHeader = h
//                    }
//                   
//                }
//            }
//            
//        }
//        
//        let est = j["Est"]
//        connectionTiming = Double(est.stringValue)!
//        let rjson = j["Rule"]
//        rule.mapObject(rjson)
//        
//        self.reqID = j["reqID"].uIntValue
//        self.subID = j["subID"].uIntValue
//        let transf = j["transferTiming"]
//        self.transferTiming = Double(transf.stringValue)!
//        
//        self.traffice.mapObject(j: j["Traffic"])
//
//        
//        self.eTime = Date.init(timeIntervalSince1970: j["end"].doubleValue)
//        self.interfaceCell = j["interfaceCell"].int64Value
//        self.localIPaddress = j["localIP"].stringValue
//        self.remoteIPaddress = j["remoteIP"].stringValue
//        
//    }

    public func dataDesc(_ d:Date) ->String{
        
        let zone = TimeZone.current
        let formatter = DateFormatter()
        formatter.timeZone = zone
        formatter.dateFormat = "HH:mm:ss"
        //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: d)
    }
    public func writeFLow(){
        //XProxy.log("[SFRequestInfo-\(reqID)] write data",level: .Debug)
        #if LOGGER
        let url1 = groupContainerURL().appendingPathComponent("\(url)\(reqID)_\(sTime)send.bin")
        try! sendData.write(to: url1, options: .atomic)
        let url2 = groupContainerURL().appendingPathComponent("\(url)\(reqID)_\(sTime)recv.bin") 
        try! recvData.write(to: url2, options: .atomic)
        #endif
    }

    public func updateSendTraffic(_ t:Int){
        let stat = SFVPNStatistics.shared
        traffice.addTx(x: t)
        if interfaceCell == 0 {
            //WIFI
            stat.wifiTraffice.addTx(x: t)
        }else {
            stat.cellTraffice.addTx(x: t)
        }
        if let _  = proxy {
           stat.proxyTraffice.addTx(x: t)
        }else {
            stat.directTraffice.addTx(x: t)
        }
        activeTime = Date()
    }
    public func updaterecvTraffic(_ t:Int){
        let stat = SFVPNStatistics.shared
        traffice.addRx(x: t)
        if interfaceCell == 0 {
            //WIFI
            stat.wifiTraffice.addRx(x: t)
        }else {
            stat.cellTraffice.addRx(x: t)
        }
        if let _  = proxy {
            stat.proxyTraffice.addRx(x: t)
        }else {
            stat.directTraffice.addRx(x: t)
        }
        activeTime = Date()
    }
    deinit {
        
        writeFLow()
        
        //
//        reqHeader = nil
//        respHeader = nil
        //NSLog("[SFRequestInfo-\(reqID)] \(mode.description) \(url) deinit \(traffice.rx):\(traffice.tx)")
        //AxLogger("")
    }
}
extension SFRequestInfo: Equatable {}

public func ==(lhs:SFRequestInfo,rhs:SFRequestInfo) -> Bool {
    
    return (lhs.reqID == rhs.reqID) && (lhs.subID == rhs.subID)
}
