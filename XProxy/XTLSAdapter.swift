//
//  XTLSAdapter.swift
//  XProxy
//
//  Created by yarshure on 2018/1/19.
//  Copyright © 2018年 yarshure. All rights reserved.
//

import Foundation
import Security
class SSecurtXconHelper {
    static let helper = SSecurtXconHelper()
    var list:[UInt32:TLSSocketProvider] = [:]
    func add(_ key:UInt32,value:TLSSocketProvider){
        list[key] = value
    }
}

open class TLSSocketProvider {
    var tlsReadBuffer:Data = Data()
    var tlsAdapter:XTLSAdapter?
    //write cipher data to remote
    func write(_ data:Data){
        XProxy.log("should write \(data as NSData)", level: .Info)
    }
    init() {
        
    }
    //handshake finished call
    func didSecure(){
        
    }
}

class XTLSAdapter {
    var ctx:SSLContext!
    var certState:SSLClientCertificateState!
    var negCipher:SSLCipherSuite!
    
    var negVersion:SSLProtocol!
    let handShakeTag:Int = -3000
    var handShanked:Bool = false
    var dispatchQueue:DispatchQueue
    weak var provider:TLSSocketProvider!
    //let tlsqueue = DispatchQueue(label:"tls.handshake.queue")
    func check(_ status:OSStatus) {
        if status != 0{
            if let str =  SecCopyErrorMessageString(status, nil) {
                XProxy.log("\(status):" +  (str as String),level: .Info)
                
            }
            
            
        }
    }
    init(side:SSLProtocolSide,type:SSLConnectionType,provider:TLSSocketProvider,queue:DispatchQueue) {
        if let x = SSLCreateContext(kCFAllocatorDefault, side,type){
            ctx = x
        }else {
            fatalError()
        }
        self.dispatchQueue = queue
        self.provider = provider
        config(side)
    }
    func config(_ side:SSLProtocolSide){
        var status: OSStatus
        status = SSLSetIOFuncs(ctx, readFunc(), writeFunc())
        check(status)
        
        let ptr = Unmanaged.passRetained(provider)
       
        let connection = UnsafeRawPointer.init(ptr.toOpaque())
        status = SSLSetConnection(ctx, connection)
        check(status)
        if side == .clientSide {
            status = SSLSetSessionOption(ctx, SSLSessionOption.breakOnClientAuth, true)
            check(status)
        }
    }
    func setPeer( _ host:String){
        SSLSetPeerDomainName(ctx, host, host.count)
    }
    func setCerts(_ certs:[Data]){
        //0:SecIdentityRef, SecCertificateRefs
    }
    func setCert(_ certRefs:Array<Any>){
        let status = SSLSetCertificate(ctx, certRefs as CFArray)
        check(status)
    }
    
    func handShake() ->Bool{
        if handShanked {
            return true
        }
        var status: OSStatus
        status = SSLHandshake(self.ctx);
        var state:SSLSessionState = SSLSessionState.init(rawValue: 0)!
        SSLGetSessionState(self.ctx, &state)
        XProxy.log("SSLHandshake...state:" + state.description, level: .Info)
        if status == errSSLWouldBlock {
            XProxy.log("SSLHandshake... waiting for next call ", level: .Info)
            return false
        }else {
            self.handShanked = true
            
            //self.provider.didSecure()
            XProxy.log("SSLHandshake...Finished ", level: .Info)
            return true
        }
        
        
        
    }
    //SSLWrite(_ context: SSLContext, _ data: UnsafeRawPointer?, _ dataLength: Int, _ processed: UnsafeMutablePointer<Int>) -> OSStatus

    func writeData(data:Data) ->Int{
        var result:UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        defer {
            result.deallocate(capacity: 1)
        }
        let len:Int = data.count
        _ = data.withUnsafeBytes { (ptr)  in
            SSLWrite(ctx, ptr, len, result)
        }

        let r = result.pointee
        return r
    }
    //SSLRead(_ context: SSLContext, _ data: UnsafeMutableRawPointer, _ dataLength: Int, _ processed: UnsafeMutablePointer<Int>)
    func readData(_ max:Int) ->Data?{
        var result:UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        defer {
            result.deallocate(capacity: 1)
        }
        var buffer:Data = Data.init(capacity: max)
        _ = buffer.withUnsafeMutableBytes { ptr  in
            SSLRead(ctx, ptr , max,   result)
        }
        if result.pointee > 0 {
            buffer.count = result.pointee
            return buffer
        }
        return nil
    }
    //SSLConnectionRef, UnsafeRawPointer, UnsafeMutablePointer<Int>
    func readFunc() ->SSLReadFunc {
        return { c,data,len in
            let socketfd:TLSSocketProvider  = c.assumingMemoryBound(to: TLSSocketProvider.self).pointee
            let bytesRequested = len.pointee
            // Read the data from the socket...
            if socketfd.tlsReadBuffer.isEmpty {
                //无数据
                XProxy.log("no data", level: .Info)
                len.initialize(to: 0)
                return OSStatus(errSSLWouldBlock)
            }else {
                //
                var toRead:Int = 0
                if socketfd.tlsReadBuffer.count >= bytesRequested {
                    toRead = bytesRequested
                }else {
                    toRead = socketfd.tlsReadBuffer.count
                    
                }
                memcpy(data, (socketfd.tlsReadBuffer as NSData).bytes,toRead)
                socketfd.tlsReadBuffer.removeSubrange( 0..<toRead)
                
                len.initialize(to: toRead)
                if bytesRequested > toRead {
                    
                    return OSStatus(errSSLWouldBlock)
                    
                } else {
                    
                    return noErr
                }
            }
           
        }
    }
    //SSLConnectionRef, UnsafeRawPointer, UnsafeMutablePointer<Int>
    func writeFunc() ->SSLWriteFunc {
        return { c,data,len in
           
            let socketfd:TLSSocketProvider = c.assumingMemoryBound(to: TLSSocketProvider.self).pointee
           
            var buffer:Data = Data.init(count: len.pointee)
            _ = buffer.withUnsafeMutableBytes { ptr  in
                memcpy(ptr, data, len.pointee)
            }
            socketfd.write(buffer)
            //con!.test("write")
            return 0
        }
    }
}
