//
//  XTLSAdapter.swift
//  XProxy
//
//  Created by yarshure on 2018/1/19.
//  Copyright © 2018年 yarshure. All rights reserved.
//

import Foundation
import Security
import DarwinCore


open class TLSSocketProvider {
    var tlsReadBuffer:Data = Data()
    var tlsAdapter:XTLSAdapter?
    //write cipher data to remote
    func write(_ data:Data){
        XProxy.log("should write \(data as NSData)", level: .Info)
    }
    public init() {
        
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
    func check(_ status:OSStatus,funcName:String =  "") {
        if status != 0{
            #if os(macOS)
            if let str =  SecCopyErrorMessageString(status, nil) {
                XProxy.log(funcName + " status: \(status):" +  (str as String),level: .Info)
                
            }
            #else
            #endif
            
            
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
        check(status,funcName: "SSLSetIOFuncs")
        
        status = SSLSetConnection(ctx, Unmanaged.passUnretained(provider).toOpaque())
        check(status,funcName: "SSLSetConnection")
        if side == .clientSide {
            status = SSLSetSessionOption(ctx, SSLSessionOption.breakOnClientAuth, true)
            check(status,funcName:"SSLSetSessionOption")
        }
//        status = SSLSetProtocolVersionMin(ctx, SSLProtocol.tlsProtocol1)
//        check(status,funcName:"SSLSetProtocolVersionMin" )
//        status = SSLSetProtocolVersionMax(ctx, SSLProtocol.tlsProtocol12)
//        check(status,funcName: "SSLSetProtocolVersionMax")
        
        var numEnabled:Int = 0
        status = SSLGetNumberEnabledCiphers(ctx, &numEnabled)
        print("SSLGetNumberEnabledCiphers count \(numEnabled)")
        check(status,funcName: "SSLGetNumberEnabledCiphers")
        
       
    
//        var numSupported:Int = 200
//        var supported:UnsafeMutablePointer<SSLCipherSuite> = UnsafeMutablePointer<SSLCipherSuite>.allocate(capacity: numEnabled)
//        
//        defer {
//            supported.deallocate(capacity: 200)
//        }
//        
//        status = SSLGetSupportedCiphers(ctx,supported , &numSupported)
//        print("SSLGetSupportedCiphers count \(numSupported)")
//        check(status,funcName: "SSLGetSupportedCiphers")
        
        
        
        let enabled:UnsafeMutablePointer<SSLCipherSuite> = UnsafeMutablePointer<SSLCipherSuite>.allocate(capacity: 1)
        //var enableTemp =
        //var toEnable:Int = 0
        enabled.pointee = TLS_RSA_WITH_AES_256_GCM_SHA384
       //enabled.initialize(from: supported, count: numSupported)
//        for x in 0..<numSupported {
//            //if supported.pointee !=
//            enabled.pointee = supported.pointee
//            supported = supported.successor()
//
//        }
        status = SSLSetEnabledCiphers(ctx, enabled, 1)
        check(status,funcName: "SSLSetEnabledCiphers")

    }
 
    func setPeer( _ host:String){
        let status = SSLSetPeerDomainName(ctx, host, host.count)
        check(status,funcName: "SSLSetPeerDomainName")
    }
    func setCerts(_ certs:SecTrust,caRefs:[String:Any]){
        //0:SecIdentityRef, SecCertificateRefs
        let originCert:SecCertificate? = SecTrustGetCertificateAtIndex(certs, 0)
        let serverCerts =  TLSToolCommon().logCertificateData(for: certs)
        print(serverCerts as Any)
        let myOIDs : NSDictionary = copyOID(certificate: originCert!)
        
        
        var publicKey:SecKey?  = copyPublicKey(caCertificate: originCert!)
     
        let certDict = caRefs as [String:AnyObject]
        let secIdentityRef  = certDict[kSecImportItemKeyID as String]
        //    -- Cert chain...
        var p12Certs = [secIdentityRef]
        if let o = originCert {
            p12Certs.append(o)
        }
        var caCertificate:SecCertificate?
        var ccerts: Array<SecCertificate> = (certDict as AnyObject).value(forKey: kSecImportItemCertChain as String) as! Array<SecCertificate>
        for i in 0 ..< ccerts.count {
            if i == 0 {
                caCertificate = ccerts[i]
            }
            p12Certs += [ccerts[i] as AnyObject]
        }
        let carpublicKey = copyPublicKey(caCertificate: caCertificate!)
        let status = SSLSetCertificate(ctx, p12Certs as CFArray)
        check(status,funcName:"SSLSetCertificate")
    }
    
    func showState() ->SSLSessionState  {
        var state:SSLSessionState = SSLSessionState.init(rawValue: 0)!
        SSLGetSessionState(self.ctx, &state)
        XProxy.log("SSLHandshake...state:" + state.description, level: .Info)
        return state
        
    }
    func handShake() ->Bool{
        if handShanked {
            return true
        }
        var status: OSStatus
        status = SSLHandshake(self.ctx);
        check(status,funcName:"SSLHandshake")
        
        if status == errSSLWouldBlock {
            XProxy.log("SSLHandshake... waiting for next call ", level: .Info)
            return false
        }else {
            
            if showState() == .connected {
                self.handShanked = true
            }else {
                
            }
            //self.provider.didSecure()
            XProxy.log("SSLHandshake...Finished ", level: .Info)
            return true
        }
        
        
        
    }
    //SSLWrite(_ context: SSLContext, _ data: UnsafeRawPointer?, _ dataLength: Int, _ processed: UnsafeMutablePointer<Int>) -> OSStatus

    func writeData(data:Data) ->Int{
        var result:UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        defer {
            result.deallocate()
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
            result.deallocate()
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
            //let socketfd:TLSSocketProvider  = c.assumingMemoryBound(to: TLSSocketProvider.self).pointee
            
            let unmanaged:Unmanaged<TLSSocketProvider>  =   Unmanaged.fromOpaque(c)
            let socketfd:TLSSocketProvider = unmanaged.takeUnretainedValue()
            
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
                XProxy.log("tls read \(toRead) left:\(socketfd.tlsReadBuffer.count)", level: .Info)
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
           
            let unmanaged:Unmanaged<TLSSocketProvider>  =   Unmanaged.fromOpaque(c)
            let socketfd:TLSSocketProvider = unmanaged.takeUnretainedValue()
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
