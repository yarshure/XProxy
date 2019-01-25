//
//  ext.swift
//  XProxy
//
//  Created by yarshure on 2017/11/23.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Foundation
import XRuler
import Xcon
var SFConnectionID:UInt = 0
public enum HTTPConnectionState:Int,CustomStringConvertible {
    case httpDefault = 0
    case httpReqHeader = 1
    case httpReqBody = 2
    case httpCONNECTSending = 3
    case httpCONNECTRecvd = 4
    case httpReqSending = 5
    case httpReqSended = 6
    case httpRespHeader = 7
    case httpRespBody = 8
    case httpRespFinished = 9
    case httpRespReading = 10 //长链接,chunked mode
    
    public var description: String {
        switch self {
        case .httpDefault: return "HttpDefault"
        case .httpReqHeader: return "HttpReqHeader"
        case .httpReqBody : return  "HttpReqBody"
        case .httpCONNECTSending: return "HttpCONNECTSending"
        case .httpCONNECTRecvd: return "HttpCONNECTRecvd"
        case .httpReqSending: return "HttpReqSending"
        case .httpReqSended : return "HttpReqSended"
        case .httpRespHeader : return "HttpRespHeader"
        case .httpRespBody : return "HttpRespBody"
        case .httpRespFinished : return "HttpRespFinished"
        case .httpRespReading :return "HttpRespReading"
        }
    }
}
public enum SocketEvent: Int {
    case event_ERROR = 1
    case event_UP = 2
    case event_ERROR_CLOSED = 3
}
public enum SFConnectionStatus :String{
    case Start = "Start"
    case Connectioning = "Connectioning"
    case Established = "Established"
    //    case Reading = "Reading"
    //    case Writing = "Writing"
    case Transferring = "Transferring"
    case RecvWaiting = "RecvWaiting"
    case SendWaiting = "SendWaiting"
    case Closing = "Closing"
    case Complete = "Complete"
    public var description: String {
        switch self {
        case .Start: return "Start"
        case .Connectioning: return "Connectioning"
        case .Established : return "Established"
            //        case Reading : return  "Reading"
        //        case Writing : return  "Writing"
        case .Transferring: return "Transferring"
        case .RecvWaiting: return "RecvWaiting"
        case .SendWaiting:return "SendWaiting"
        case .Closing: return "Closing"
        case .Complete: return "Complete"
        }
    }
}
public enum SFConnectionCompleteReason :Int{
    
    case noError = 0
    case badConfig = 1
    case badParam = 2
    case connectTimeout = 3
    case readTimeout = 4
    case writeTimeout = 5
    case readMaxedOut = 6
    case closedError = 7
    case otherError = 8
    
    case clientReject = 9
    case authFail = 10
    case idelTooLong = 11
    
    
    
    public var description: String {
        switch self {
        case .noError : return "No Error"
        case .badConfig: return "Bad Config"
        case .badParam: return "BadParam"
        case .connectTimeout: return "ConnectTimeout"
        case .readTimeout: return "Read Timeout"
        case .writeTimeout: return "Write Timeout"
        case .readMaxedOut: return "Read MaxedOut"
        case .closedError: return "remote closed"
        case .otherError: return "Other Error"
            
        case .clientReject: return "Reject"
        case .authFail: return "Auth Fail"
        case .idelTooLong: return "Idel Too Long"
        }
    }
}
extension SFHTTPRequestHeader {
    public func checkMitm() ->Bool {
        return SFSettingModule.setting.checkRemoteMitm(Host)
    }
    public func checkRewrite() ->Bool{
        //rewrite
//        if  let r =  SFSettingModule.setting.rule{
//            if let ruler = r.rewriteRule(self.Url){
//                if ruler.type == .header {
//                    if let r = self.Url.range(of: ruler.name){
//                        self.Url.replaceSubrange(r, with: ruler.proxyName)
//                        let dest = ruler.proxyName
//                        let dlist = dest.components(separatedBy: "/")
//                        for dd in dlist {
//                            if !dd.isEmpty && !dd.hasPrefix("http"){
//                                self.params["Host"] = dd
//                                return true
//                            }
//                            
//                        }
//                        
//                        
//                        
//                    }
//                }
//                
//                
//            }
//        }
        return false
    }
}
extension SFRequestInfo {
    public func findProxy(_ r:SFRuleResult,cache:Bool) {
        
        rule = r.result
        rule.timming = self.ruleTiming
        if cache {
            //.addRuleResult(r)
        }
        
        let x = String.init(format: "%.2f second", rule.timming)
        XProxy.log("\(reqID)-\(host) found rule now timing \(x) ,begin find proxy rule:\(rule.policyString())",level: .Trace)
        //NSLog("%@ %@",dest,useragent)
        
        switch  rule.policy{
        case .Direct:
            
            break
        case .Random:
            self.proxy = SFSettingModule.setting.randomProxy()
        case .Reject:
            
            break
        case .Proxy:
            guard let proxy = SFSettingModule.setting.proxyByName(rule.proxyName) else {
                return
            }
            self.proxy = proxy
            //reqInfo.rule.policy = .Proxy
            
        }
        let message3 = String.init(format: "%@ %@",url, self.rule.policy.description)
        
        XProxy.log("\(message3) recv result , now exit waiting",level:.Debug)
        if waitingRule {
            waitingRule = false
        }
        if let p = proxy {
            rule.proxyName = p.proxyName
        }
        
    }
    public func checkReadFinish(_ data:Data) ->(Bool,Int){
        let  len:Int = data.count
        guard let header = respHeader else {return (false,0)}
        let BodyLength  = header.contentLength
        // let headLength = header.length
        
        if self.app.hasSuffix("WeChat"){
            if let size = header.params["Size"]{
                
                self.respHeader!.mode = .ContentLength
                self.respHeader!.bodyLeftLength = Int(size)!
            }
        }
        
        
        //        for (k,v) in header.params {
        //            NSLog("HEADER PARAMS:%@ %@", k,v)
        //        }
        
        
        if header.mode == .ContentLength {
            
            
            XProxy.log("HTTP \(header.mode) BodyLength: \(BodyLength) left:\(header.bodyLeftLength) recv len:\(len)", level: .Debug)
            
            if header.bodyLeftLength  == 0 {
                respReadFinish = true
                return (respReadFinish,0)
            }
            if header.bodyLeftLength <= len  {//勾了
                let used = header.bodyLeftLength
                respReadFinish = true
                //let left = len - header.bodyLeftLength
                //traffice.addRx(x: header.bodyLeftLength)
                header.bodyLeftLength = 0
                //print("\(url) Body Recv \(header.bodyReadLength): \(BodyLength)")
                
                return (respReadFinish,used)
            }else {
                //header.bodyLeftLength > len
                header.bodyLeftLength -= len
                //traffice.addRx(x: len)
                return (false,len)
            }
        }else if header.mode == .TransferEncoding{
            //traffice.addRx(x: len)//bodylen
            XProxy.log("HTTP \(header.mode) received:\(traffice.rx)",level:.Trace)
            let (r,used) = header.parser(data)
            respReadFinish = r
            return (r,used)
        }else {
            //            if contentLength !== 0 {
            //
            //            }else {
            //
            //            }
            //XProxy.log("HTTP header .mode error \(header.params)",level:.Debug)
            //traffice.addRx(x: len)
            //header.length += len
            header.contentLength += len
            //used += len
            return (false,len)
        }
        
    }
    
    public func shouldClose() ->Bool {
        
        if mode == .TCP {
            if idleTimeing > XProxy.TCP_MEMORYWARNING_TIMEOUT{
                return true
            }else {
                return false
            }
        }
        
        guard let resp  = respHeader else {return false}
        guard let req = reqHeader else {return false}
        var result = false
        if req.method == .CONNECT {
            if idleTimeing > XProxy.TCP_MEMORYWARNING_TIMEOUT {
                result = true
            }
        }else {
            if let c = resp.params["Connection"], c == "close"{
                
                if idleTimeing > XProxy.TCP_MEMORYWARNING_TIMEOUT  {
                    result = true
                }
            }
        }
        
        return result
    }
}

extension SFProxy{
    var connectHost:String {
        var host:String = serverAddress
//        if !serverIP.isEmpty {
//            if SFEnv.ipType == .ipv6 {
//                host = "::ffff:" + serverIP
//            }else {
//                host = serverIP
//            }
//            
//        }
        return host
    }
}
extension SFHTTPRequestHeader {
//    func checkRewrite() ->Bool{
//        //rewrite
//        if  let r =  SFSettingModule.setting.rule{
//            if let ruler = r.rewriteRule(self.Url){
//                if ruler.type == .header {
//                    if let r = self.Url.range(of: ruler.name){
//                        self.Url.replaceSubrange(r, with: ruler.proxyName)
//                        let dest = ruler.proxyName
//                        let dlist = dest.components(separatedBy: "/")
//                        for dd in dlist {
//                            if !dd.isEmpty && !dd.hasPrefix("http"){
//                                self.params["Host"] = dd
//                                return true
//                            }
//
//                        }
//
//
//
//                    }
//                }
//
//
//            }
//        }
//        return false
//    }
}

extension SFHTTPResponseHeader {
    func parser(_ data:Data) ->(Bool,Int){
        
        var used:Int = 0
        let total = data.count
        let opt = NSData.SearchOptions.init(rawValue: 0)
        var packets :[chunked] = []
        XProxy.log("bodyLeftLength left:\(bodyLeftLength) new data len:\(data.count)",level: .Trace)
        if let chunk_packet = chunk_packet {
            //last 没有读完
            if total >= chunk_packet.leftLen {
                
                used += chunk_packet.leftLen
                bodyLeftLength = 0
                XProxy.log("used:\(used) left:\(bodyLeftLength) Finished",level: .Trace)
                self.chunk_packet = nil
                //inst 是结束\r\n
                
                used += sepData.count
            }else {
                
                used += total
                self.chunk_packet!.leftLen -= used
                bodyLeftLength -= used
                XProxy.log("used:\(used) left:\(bodyLeftLength) not Finished ",level: .Trace)
                return (false,used)
            }
        }else {
            ////兼容完成bug是问题
            if total >= bodyLeftLength {
                used += bodyLeftLength
            }else {
                used += total
            }
        }
        while used < total {
            
            //let start = data.startIndex.advanced(by: used)
            //let end = data.startIndex.advanced(by: data.count - used)
            let r = data.range(of:sepData, options: opt, in: used ..< data.count )
            
            if let r =  r  {
                XProxy.log("used length: \(used) sepdata location:\(r)",level: .Trace)
                //let l = data.subdata(with: NSMakeRange(used, r.location - used))
                let l = data.subdata(in: used ..< r.upperBound )
                
                used += l.count // count length
                used += r.length() //算上\r\n
                
                let c_leng = Int(hexDataToInt(d: l))
                contentLength += c_leng
                if c_leng == 0 {
                    
                    if let r2 = data.range(of: sepData, options: opt, in: used ..< data.count ){
                        used += r2.length()
                    }
                    if used == total{
                        XProxy.log("used length: \(used) Last Find",level: .Trace)
                        bodyLeftLength = 0
                        chunk_packet = nil
                        //finished = true
                        return (true,used)
                    }
                    
                }
                XProxy.log("thunk len: \(c_leng) check:\(used + c_leng):\(total)",level: .Debug)
                if used + c_leng <= total {
                    let p = chunked.init(l: c_leng,left:0)
                    if used + c_leng == total {
                        //缺\r\n
                        chunk_packet = nil//chunked.init(l: c_leng,left:2)
                        bodyLeftLength = sepData.count
                        //p.data = data.subdataWithRange(NSMakeRange(used, c_leng))
                    }else {
                        //多了怎么算
                        packets.append(p)
                        used += c_leng
                        
                        used += sepData.count //\r\n chunk fins
                        XProxy.log("found chunk fins\(used) \(r)  \(used) ", level: .Debug)
                    }
                    
                }else {
                    
                    bodyLeftLength = c_leng - (total - used)
                    chunk_packet = chunked.init(l: c_leng, left: bodyLeftLength)
                    used = total
                    XProxy.log("found \(used + c_leng ) left:\(bodyLeftLength)  \(r) \(used) ", level: .Debug)
                    return (false,used)
                }
                
            }else {
                XProxy.log("Don't Find sepdata",level: .Debug)
                return (false,used)
            }
            
        }
        return (false,used)
        
    }
}

