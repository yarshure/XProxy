//
//  AppDelegate.swift
//  XProxyTest
//
//  Created by yarshure on 2017/11/23.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Cocoa
import XProxy
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func test(){
        let clientTree:AVLTree = AVLTree<Int32,String>()
        clientTree.insert(key: 1, payload: "abc")
        clientTree.insert(key: 2, payload: "bcd")
        clientTree.insert(key: 3, payload: "3")
        print(clientTree.debugDescription)
        
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        test()
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

