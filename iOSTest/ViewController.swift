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
        
        testHTTPKCP()
        print(ProxyGroupSettings.share.proxys)
        if let x = SFSettingModule.setting.findRuleByString("secure-appldnld.apple.com", useragent: ""){
            print(x.result.type)
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

