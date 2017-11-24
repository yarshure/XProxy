//
//  ViewController.swift
//  XProxyTest
//
//  Created by yarshure on 2017/11/23.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Cocoa
import XProxy
class ViewController: NSViewController {

    @IBAction func start(_ sender: Any) {
        XProxy.startGCDProxy()
    }
    @IBAction func pause(_ sender: Any) {
        XProxy.startGCDProxy()
    }
    @IBAction func restart(_ sender: Any) {
        XProxy.startGCDProxy()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

