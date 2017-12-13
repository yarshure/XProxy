//
//  SocketManager.swift
//  XProxy
//
//  Created by yarshure on 2017/11/23.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Foundation
import DarwinCore
class SocketManager {
    static var shared = SocketManager()
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
    public var dispatchQueue:DispatchQueue// = dispatch_queue_create("com.yarshure.dispatch_queue", DISPATCH_QUEUE_SERIAL);
    var socketQueue:DispatchQueue //=
    init() {
        dispatchQueue = DispatchQueue(label: "com.yarshure.dispatchqueue")
        socketQueue =  DispatchQueue(label:"com.yarshure.socketqueue")
    }
    func saveTunnelConnectionInfo(_ c:HTTPConnection){
        XProxy.saveTunnelConnectionInfo(c)
    }
    public func startGCDServer(port:Int32){
        let server = GCDSocketServer.shared()
        switch st {
        case .Stoped:
            //suport stoped?
            print(st.description + "don't support ")
        case .Running:
            return
        default:
            server.pauseRestart()
            print(st.description)
            st = .Running
            return
        }
        
        
        
            server.accept = { fd,addr,port in
                let c = HTTPConnection.init(sfd: fd, rip: addr, rport: UInt16(port), dip: "127.0.0.1", dport: 10081)
                c.manager = self
                self.clientTree.insert(key: fd, payload: c)
                //c.connect()
                print("welcome \(fd) \(String(describing: addr)):\(port)")
            }
            server.colse = { fd in
                
                //self.clientTree.delete(key: fd)
                if let c = self.clientTree.search(input: fd){
                    print("\(fd):found connection \(c.reqInfo.reqID),cleaning...")
                    c.forceCloseRemote()
                    self.clientTree.delete(key: fd)
                }else {
                    print("bye:\(fd) close,don't found client")
                }
            }
            server.incoming  = { fd ,data in
                print("\(fd) incoming \(String(describing: data))")
                
                if let c = self.clientTree.search(input: fd){
                    c.incommingData(data,len:data.count)
                    
                }
                //server.server_write_request(fd, buffer: "wello come\n", total: 11);
            }
            //let q = DispatchQueue.init(label: "dispatch queue")
            server.start(port, queue: self.dispatchQueue)
        st = .Running
    }
    func stopServer(){
        XProxy.log("currently not support", level: .Info)
        st = .Stoped
    }
    func pauseServer(){
        GCDSocketServer.shared().pauseRestart()
        st = .Pause
    }
}
