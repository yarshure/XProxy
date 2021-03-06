//
//  SocketManager.swift
//  XProxy
//
//  Created by yarshure on 2017/11/23.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Foundation
import DarwinCore
public typealias socketCompleteCallBack = (SFRequestInfo) -> Swift.Void
import XRuler
class SocketManager {
    //static var shared = SocketManager()
    public enum State: CustomStringConvertible{
        case Stoped
        case Running
        case Pause
        public var description: String {
            get {
                switch self {
                case .Stoped:
                    return "HTTP Proxy Server Stopped"
                case .Running:
                    return "HTTP Proxy Server Running"
                default:
                    return "HTTP Proxy Server Pause"
                }
            }
            
        }
    }
    public var st:State = .Stoped
    var clientTree:AVLTree = AVLTree<Int32,HTTPConnection>()
    var dispatchQueue:DispatchQueue
    
    var socketQueue:DispatchQueue
    var callBack:socketCompleteCallBack?
    let server = GCDSocketServer()
    init(dispatch:DispatchQueue?,socket:DispatchQueue?) {
        if let dispatch = dispatch {
            self.dispatchQueue = dispatch
        }else {
            //self.dispatchQueue = DispatchQueue.global()
             self.dispatchQueue  = DispatchQueue.init(label: "com.yarshure.proxy.dispatch")
        }
        if let socket = socket {
            self.socketQueue = socket
        }else {
            //self.socketQueue = DispatchQueue.global()
            self.socketQueue =  DispatchQueue.init(label: "com.yarshure.proxy.socket")
        }
        
        
    }
    func saveConnection(_ info:SFRequestInfo,fdClose:Int32 = 0){
        guard let call = callBack else {return}
        call(info)
        if fdClose != 0 {
            //close it , and delete connection
            close(fdClose);//
            self.closeConnection(fd: fdClose, remote: true)
        }
       
    }
    func closeConnection(fd:Int32,remote:Bool = false){
        //self.clientTree.delete(key: fd)
        if let c = self.clientTree.search(input: fd){
            XProxy.log("\(fd):found connection \(c.reqInfo.reqID)", level: .Trace)
            if !remote {
                c.forceCloseRemote()
            }
            
            self.clientTree.delete(key: fd)
        }else {
            XProxy.log("\(fd):not found connection, shutdown?", level: .Error)
            
        }
    }
    public func startGCDServer(port:Int32,socketComplete:socketCompleteCallBack?,share:Bool){
        self.callBack = socketComplete
        
        switch st {
        case .Stoped:
            //suport stoped?
            print(st.description + " don't support")
        case .Running:
            return
        default:
            server.pauseRestart()
            print(st.description)
            st = .Running
            return
        }
        
            server.accept = { [unowned self]  fd,addr,port in
                let c = HTTPConnection.init(sfd: fd, rip: addr, rport: UInt16(port), dip: "127.0.0.1", dport: 10081)
                c.manager = self
                self.clientTree.insert(key: fd, payload: c)
                //c.connect()
                XProxy.log("welcome \(fd) \(String(describing: addr)):\(port)", level: .Notify)
                
            }
            server.colse = {[unowned self] fd in
                self.closeConnection(fd:fd)
                
            }
            server.incoming  = { [unowned self] fd ,data in
                
                if let c = self.clientTree.search(input: fd){
                    c.incommingData(data,len:data.count)
                    
                }
                //report
                self.networkReport(count: data.count, tx: true)
            }
            //let q = DispatchQueue.init(label: "dispatch queue")
        server.start(port, dispatchQueue: self.dispatchQueue, socketQueue: self.socketQueue, share: share)
        SFVPNStatistics.shared.startReporting()
        st = .Running
    }
    func networkReport(count:Int,tx:Bool){
        if tx {
             SFVPNStatistics.shared.currentTraffice.addTx(x: count)
        }else {
            SFVPNStatistics.shared.currentTraffice.addRx(x: count)
        }
       
    }
    func stopServer(){
        XProxy.log("currently not support", level: .Info)
        SFVPNStatistics.shared.cancelReporting()
        st = .Stoped
    }
    func pauseServer(){
        server.pauseRestart()
        st = .Pause
    }
    // Close add current from Cell to WI-FI, cell socket not error
    //  WI-FI to cell , socket recv/send will error,auto disconnect
    func networkChange(){
        if let connections = clientTree.toPayPloadArray(){
            for c in connections  {
                close(c.socketfd)//close this socket
                c.forceCloseRemote()
            }
        }
    }
    func requsts() ->[SFRequestInfo] {
     
        var infos:[SFRequestInfo] = []
        if let connections = clientTree.toPayPloadArray(){
            for x in connections  {
                if !x.reqInfo.url.isEmpty {
                    infos.append(x.reqInfo)
                }
            }
        }
        return infos
     }
}
