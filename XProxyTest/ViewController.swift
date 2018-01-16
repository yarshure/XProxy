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
import XSocket
class TestViewController: NSViewController {

    //test
    // curl -O  -x http://127.0.0.1:10081  https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4
    let proxyServer = XProxy()
    @IBOutlet weak var stateLabel: NSTextField!
    @IBAction func start(_ sender: Any) {
        
        proxyServer.startGCDProxy(port: 10081, dispatchQueue: nil, socketQueue: nil){ info in
            print(info)
            
        }
    }
    
    @IBAction func reqs(_ sender: Any) {
        
        let proxyInfos = proxyServer.runningRequests()
        
    }
    @IBAction func pause(_ sender: Any) {
        proxyServer.pauseContinueServer()
    }
    @IBAction func restart(_ sender: Any) {
        proxyServer.pauseContinueServer()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        Xcon.debugEnable = true
        //XSocket.debugEnable = true
        XProxy.debugEanble = true
        XRuler.groupIdentifier = "745WQDK4L7.com.yarshure.Surf"
        var url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: XRuler.groupIdentifier)!
         url.appendPathComponent("abigt.conf")
        SFSettingModule.setting.config(url.path)
        
        
        
        testHTTPKCP()
        print(ProxyGroupSettings.share.proxys)
        if let x = SFSettingModule.setting.findRuleByString("secure-appldnld.apple.com", useragent: ""){
            print(x.result.type)
        }
        stateLabel.stringValue = proxyServer.state()
        // Do any additional setup after loading the view.
    }

   
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

