//
//  ViewController.swift
//  iOSTest
//
//  Created by yarshure on 2018/1/2.
//  Copyright © 2018年 yarshure. All rights reserved.
//

import UIKit

import Xcon
import XProxy
import XRuler
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Xcon.debugEnable = true
        XProxy.debugEanble = true
        XRuler.groupIdentifier = "group.com.yarshure.Surf"
        var url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: XRuler.groupIdentifier)!
        url.appendPathComponent("abigt.conf")
        SFSettingModule.setting.config(url.path)
        
        
        
        testHTTP()
        print(ProxyGroupSettings.share.proxys)
        if let x = SFSettingModule.setting.findRuleByString("secure-appldnld.apple.com", useragent: ""){
            print(x.result.type)
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    func testHTTP(){
        let x = "http,192.168.11.131,8000,,"
        if let p = SFProxy.createProxyWithLine(line: x, pname: "CN2"){
            
            _  = ProxyGroupSettings.share.addProxy(p)
        }
    }
    func testSS(){
        if let p = SFProxy.create(name: "11", type: .SS, address: "35.197.117.170", port: "53784", passwd: "aHR0cHM6Ly9yYXcuZ2l0aHVidXN", method: "aes-256-cfb", tls: false) {
            _  = ProxyGroupSettings.share.addProxy(p)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

