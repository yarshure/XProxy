//
//  TUNConnection.swift
//  Surf
//
//  Created by 孔祥波 on 16/2/6.
//  Copyright © 2016年 yarshure. All rights reserved.
//

import Foundation
import Xcon
public class Connection: NSObject ,XconDelegate{
    /**
     The socket did disconnect.
     
     This should only be called once in the entire lifetime of a socket. After this is called, the delegate will not receive any other events from that socket and the socket should be released.
     
     - parameter socket: The socket which did disconnect.
     */
    public func didDisconnect(_ socket: Xcon,  error:Error?){
        
    }
    
    /**
     The socket did read some data.
     
     - parameter data:    The data read from the socket.
     - parameter withTag: The tag given when calling the `readData` method.
     - parameter from:    The socket where the data is read from.
     */
    public func didReadData(_ data: Data, withTag: Int, from: Xcon){
        
    }
    
    /**
     The socket did send some data.
     
     - parameter data:    The data which have been sent to remote (acknowledged). Note this may not be available since the data may be released to save memory.
     - parameter withTag: The tag given when calling the `writeData` method.
     - parameter from:    The socket where the data is sent out.
     */
    public func didWriteData(_ data: Data?, withTag: Int, from: Xcon){
        
    }
    
    /**
     The socket did connect to remote.
     
     - parameter socket: The connected socket.
     */
    public func didConnect(_ socket: Xcon){
        
    }

    public let info:SFIPConnectionInfo
    public var forceSend:Bool = false // client maybe close after send, proxy should sending the buffer
    public var closeSocketAfterRead:Bool = false // HTTP
    public init(i:SFIPConnectionInfo) {
        info = i
        reqInfo = SFRequestInfo.init(rID: SFConnectionID)
        
        SFConnectionID += 1
        super.init()
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
    public var rTag:Int = 1 //recv tag?
    //0 use for handshake and kcp tun use
    public var sendingTag:Int64 = -1
    
    public var forceClose:Bool = false
    public var reqInfo:SFRequestInfo
    
    public func memoryWarning(_ level:DispatchSource.MemoryPressureEvent){
        
    }
}