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
    var clientTree:AVLTree = AVLTree<Int32,HTTPConnection>()
    public var dispatchQueue:DispatchQueue// = dispatch_queue_create("com.yarshure.dispatch_queue", DISPATCH_QUEUE_SERIAL);
    var socketQueue:DispatchQueue //=
    init() {
        dispatchQueue = DispatchQueue(label: "com.yarshure.dispatchqueue")
        socketQueue =  DispatchQueue(label:"com.yarshure.socketqueue")
    }
    func saveTunnelConnectionInfo(_ c:HTTPConnection){
        
    }
    public func startGCDServer(){
        
        
        if let server = GCDSocketServer.shared(){
            server.accept = { fd,addr,port in
                let c = HTTPConnection.init(sfd: fd, rip: addr!, rport: UInt16(port), dip: "127.0.0.1", dport: 10081)
                c.manager = self
                self.clientTree.insert(key: fd, payload: c)
                //c.connect()
                print("\(fd) \(String(describing: addr)) \(port)")
            }
            server.colse = { fd in
                print("\(fd) close")
                //self.clientTree.delete(key: fd)
                if let c = self.clientTree.search(input: fd){
                    c.forceCloseRemote()
                    self.clientTree.delete(key: fd)
                }
            }
            server.incoming  = { fd ,data in
                print("\(fd) \(String(describing: data))")
                
                if let c = self.clientTree.search(input: fd){
                    c.incommingData(data!,len:data!.count)
                    
                }
                //server.server_write_request(fd, buffer: "wello come\n", total: 11);
            }
            //let q = DispatchQueue.init(label: "dispatch queue")
            server.start(10081, queue: DispatchQueue.main)
        }
        
    }
}
