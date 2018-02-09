//
//  TUNConnection.swift
//  Surf
//
//  Created by 孔祥波 on 16/2/6.
//  Copyright © 2016年 yarshure. All rights reserved.
//

import Foundation
import Xcon
import XRuler
open  class Connection :TLSSocketProvider,XconDelegate{
    public func didConnect(_ socket: Xcon, cert: SecTrust?) {
        if let tls = tlsAdapter,let sec = cert {
            
            
            var result:[String : Any]
            do {
                result =  try SFSettingModule.setting.mitmRootCA()
            }catch let e {
                XProxy.log("get root ca failure:\(e.localizedDescription)", level: .Error)
                reqInfo.mitm = false
                return
            }
            tls.setCerts(sec, caRefs: result)
        }
        XProxy.log("didconnect with SecTrust", items: "", level: .Info)
        client_socks_handler(.event_UP)
    }
    
    /**
     The socket did disconnect.
     
     This should only be called once in the entire lifetime of a socket. After this is called, the delegate will not receive any other events from that socket and the socket should be released.
     
     - parameter socket: The socket which did disconnect.
     */
    open func didDisconnect(_ socket: Xcon,  error:Error?){
        XProxy.log("didconnect", items: "", level: .Info)
    }
    
    /**
     The socket did read some data.
     
     - parameter data:    The data read from the socket.
     - parameter withTag: The tag given when calling the `readData` method.
     - parameter from:    The socket where the data is read from.
     */
    open func didReadData(_ data: Data, withTag: Int, from: Xcon){
        
    }
    
    /**
     The socket did send some data.
     
     - parameter data:    The data which have been sent to remote (acknowledged). Note this may not be available since the data may be released to save memory.
     - parameter withTag: The tag given when calling the `writeData` method.
     - parameter from:    The socket where the data is sent out.
     */
    open func didWriteData(_ data: Data?, withTag: Int, from: Xcon){
        
    }
    
    /**
     The socket did connect to remote.
     
     - parameter socket: The connected socket.
     */
    open func didConnect(_ socket: Xcon){
        XProxy.log("didconnect", items: "", level: .Info)
        
        reqInfo.interfaceCell = 0
        if let r = socket.remote {
            
            reqInfo.remoteIPaddress = r.hostname
        }
        var ipaddress:String = ""
        if let l = socket.local {
            reqInfo.localIPaddress = l.hostname
            ipaddress = l.hostname
        }
        if  SFNetworkInterfaceManager.ipForType(ipaddress) == .cell{
            reqInfo.interfaceCell = 1
        }
        
        client_socks_handler(.event_UP)
    }

    open func client_send_to_socks(){
        //debugLog("client_send_to_socks")
        assert(!reqInfo.socks_closed)
        assert(reqInfo.socks_up)
        let st = (reqInfo.status == .Established) || (reqInfo.status == .Transferring)
        if  let f = bufArray.first, st {
            //SKit.log("\(cIDString) sending buffer count \(bufArray.count)",level: .Debug)
            var sendData:Data = f
            //bug here,fixme
            for x in bufArray.dropFirst() {
                sendData.append(x)
            }
            
            
            if tag == sendingTag {
                return
            }
            guard let connector = connector  else {return }
            //SKit.log("\(cIDString) writing to Host:\(h):\(p) tag:\(tag)   length \(d.length)",level: .Trace)
            //NSLog("%@ will send data tag:%d", reqInfo.url,tag)
            bufArray.removeAll()
            //MARK: fixme
            //bufArrayInfo[tag] = sendData.count
            sendingTag = tag
            
            
            connector.writeData(sendData, withTag: Int(tag))
        }
    }
    
    open func  client_socks_handler(_ event:SocketEvent){
        
    }
    public let info:SFIPConnectionInfo
    public var forceSend:Bool = false // client maybe close after send, proxy should sending the buffer
    public var closeSocketAfterRead:Bool = false // HTTP
    public init(i:SFIPConnectionInfo) {
        info = i
        
        reqInfo = SFRequestInfo.init(rID: SFConnectionID)
        super.init()
       
        SFConnectionID += 1
        
    }
    
    public func prepareTLSServer(_ dispatchQueue:DispatchQueue){
        reqInfo.mitm = true
        
        tlsAdapter = XTLSAdapter.init(side: .serverSide, type: .streamType, provider: self, queue:dispatchQueue)
        
        
       
        
    }
    public func tlsInput(_ data:Data){
        
        self.tlsReadBuffer.append(data)
        _ = tlsAdapter!.handShake()
    }
    
    public var connector:Xcon?
    public var bufArray:[Data] = []
    public var bufArrayInfo:[Int64:Int] = [:]
    public var socks_recv_bufArray:Data = Data()
    public var socks_sendout_length:Int = 0
    public var connectorReading:Bool = false
    public var pendingConnection:Bool = true
    
    public var tag:Int64 = 0
    
    public var buf_used:Int = 0
    public var rTag:Int = -1 //recv tag?
    //0 use for handshake and kcp tun use
    public var sendingTag:Int64 = -1
    
    public var forceClose:Bool = false
    public var reqInfo:SFRequestInfo
    
    open  func memoryWarning(_ level:DispatchSource.MemoryPressureEvent){
        XProxy.log("memoryWarning ...", level: .Error)
    }
}
