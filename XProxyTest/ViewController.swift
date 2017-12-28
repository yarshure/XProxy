//
//  ViewController.swift
//  XProxyTest
//
//  Created by yarshure on 2017/11/23.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Cocoa
import XProxy
import XRuler
import Xcon
class ViewController: NSViewController {

    @IBOutlet weak var stateLabel: NSTextField!
    @IBAction func start(_ sender: Any) {
        XProxy.startGCDProxy(port: 10081)
    }
    @IBAction func pause(_ sender: Any) {
        XProxy.startGCDProxy(port: 10081)
    }
    @IBAction func restart(_ sender: Any) {
        XProxy.startGCDProxy(port: 10081)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        Xcon.debugEnable = true
        XRuler.groupIdentifier = "745WQDK4L7.com.yarshure.Surf"
        var url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: XRuler.groupIdentifier)!
         url.appendPathComponent("abigt.conf")
        SFSettingModule.setting.config(url.path)
        
        let x = "http,192.168.11.131,8000,,"
        if let p = SFProxy.createProxyWithLine(line: x, pname: "CN2"){
            
             _  = ProxyGroupSettings.share.addProxy(p)
        }
        print(ProxyGroupSettings.share.proxys)
        if let x = SFSettingModule.setting.findRuleByString("secure-appldnld.apple.com", useragent: ""){
            print(x.result.type)
        }
        stateLabel.stringValue = XProxy.state()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

