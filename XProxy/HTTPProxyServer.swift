//
//  HTTPProxyServer.swift
//  XProxy
//
//  Created by yarshure on 2018/1/1.
//  Copyright © 2018年 yarshure. All rights reserved.
//

import Foundation

import DarwinCore
class HTTPProxyServer {
    
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
    var server:SocketServer?
    var clientTree:AVLTree = AVLTree<Int,HConnection>()
    public var dispatchQueue:DispatchQueue// = dispatch_queue_create("com.yarshure.dispatch_queue", DISPATCH_QUEUE_SERIAL);
    var socketQueue:DispatchQueue //=
    init() {
        dispatchQueue = DispatchQueue(label: "com.yarshure.dispatchqueue")
        socketQueue =  DispatchQueue(label:"com.yarshure.socketqueue")
    }
    func saveTunnelConnectionInfo(_ c:HConnection){
        //XProxy.saveTunnelConnectionInfo(c)
        //SocketManager.saveTunnelConnectionInfo(self)
        XProxy.log("shoud save info", level: .Error)
    }
    public func startGCDServer(port:Int32){
        guard let server = SocketServer.init(port, dispatchQueue: self.dispatchQueue, socketQueue: self.socketQueue) else {
            fatalError()
        }
        
        self.server = server
        server.start({ (socket) in
            if let so = socket {
                let c = HConnection.init(s:so ,sfd: so.sfd, rip: so.remote, rport: UInt16(so.port), dip: "127.0.0.1", dport: 10081)
                //c.manager = self
                self.clientTree.insert(key: c.hashValue, payload: c)
                //c.connect()
                //print("welcome \(fd) \(String(describing: addr)):\(port)")
                
                
                so.dispatchQueue = self.dispatchQueue
                so.socketQueue = self.socketQueue
                //self.read(socket: so)
                c.start()
            }
        })
        
        switch st {
        case .Stoped:
            //suport stoped?
            print(st.description + " don't support")
        case .Running:
            return
        default:
            //server.pauseRestart()
            print(st.description)
            st = .Running
            return
        }
        
        
        
//        server.accept = { fd,addr,port in
//            let c = HTTPConnection.init(sfd: fd, rip: addr, rport: UInt16(port), dip: "127.0.0.1", dport: 10081)
//            c.manager = self
//            self.clientTree.insert(key: fd, payload: c)
//            //c.connect()
//            print("welcome \(fd) \(String(describing: addr)):\(port)")
//        }
       
       
    
        st = .Running
    }
    func stopServer(){
        XProxy.log("currently not support", level: .Info)
        st = .Stoped
    }
    func pauseServer(){
        //GCDSocketServer.shared().pauseRestart()
        st = .Pause
    }
}
