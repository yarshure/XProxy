//
//  env.swift
//  XProxy
//
//  Created by yarshure on 2018/1/16.
//  Copyright © 2018年 yarshure. All rights reserved.
//

import Foundation
import Xcon
import XRuler
func testHTTP(){
    let x = "http,192.168.11.131,8000,,"
    if let p = SFProxy.createProxyWithLine(line: x, pname: "CN2"){
        
        _  = ProxyGroupSettings.share.addProxy(p)
    }
}
func testHTTPKCP(){
    let x = "http,45.76.141.59,6001,,"
    ProxyGroupSettings.share.cleanDeleteProxy()
    if let p = SFProxy.createProxyWithLine(line: x, pname: "CN2"){
        p.kcptun = true
        p.config.crypt = "aes"
        _  = ProxyGroupSettings.share.addProxy(p)
    }
}
func testHTTPKCPEncryptNone(){
    let x = "http,144.34.203.132,6000,,"
    ProxyGroupSettings.share.cleanDeleteProxy()
    if let p = SFProxy.createProxyWithLine(line: x, pname: "CN2"){
        p.kcptun = true
        p.config.crypt = "none"
        _  = ProxyGroupSettings.share.addProxy(p)
    }
}
func testSS(){
    if let p = SFProxy.create(name: "11", type: .SS, address: "35.197.117.170", port: "53784", passwd: "aHR0cHM6Ly9yYXcuZ2l0aHVidXN", method: "aes-256-cfb", tls: false) {
        _  = ProxyGroupSettings.share.addProxy(p)
    }
}
