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
        stateLabel.stringValue = XProxy.state()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

