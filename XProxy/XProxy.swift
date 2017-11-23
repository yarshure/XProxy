//
//  XProxy.swift
//  XProxy
//
//  Created by yarshure on 2017/11/23.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Foundation
import AxLogger
public class XProxy{
    static let socketReadTimeout = 15.0
    static let AsyncSocketReadTimeOut = 3.0*200// 3.0*200
    static let AsyncSocketWriteTimeOut = 15.0
    static let  READ_TIMEOUT = 15.0
    static let  READ_TIMEOUT_EXTENSION = 10.0
    static let lwip_timer_second = 0.250
    
    
    static let TCP_MEMORYWARNING_TIMEOUT:TimeInterval = 2
    
    
    static let HTTP_CONNECTION_TIMEOUT:TimeInterval = 5
    static let TCP_CONNECTION_TIMEOUT:TimeInterval = 600 //HTTP_CONNECTIPN_TIMEPUT*6
    static let HTTPS_CONNECTION_TIMEOUT:TimeInterval = 60//HTTP_CONNECTIPN_TIMEPUT*3
    static let vpn_status_timer_second = 1.0
    
    static let RECENT_REQUEST_LENGTH:Int = 20
    static let SOCKET_DELAY_READ: TimeInterval = 0.050
    static let SFTCPManagerEnableDropTCP = false
    static let LimitTCPConnectionCount_DELAY:Int = 0
    static let LimitTCPConnectionCount:Int = 10
    static let LimitTCPConnectionCount_DROP:Int = 15
    static let TCP_DELAY_START = 0.5
    static let LimitMemoryUsed:UInt = 13000000//15*1024*1024 //15MB
    static let LimitStartDelay:Int = 10 //10 second
    //let BUF_SIZE:size_t = 2048
    static let LimitSpeedSimgle:UInt = 100*1024 //1KB/ms
    static let LimitLWIPInputSpeedSimgle:UInt = 3*1024 //1KB/ms
    static var memoryLimitUesedSize:UInt = 1*1024*1024
    //static let physicalMemorySize = physicalMemory()
    static let LimitSpeedTotal:UInt = 20*1024*1024//LimitSpeedSimgle //1MB/s
    static func prepare() ->Bool{
        
        return true
    }
    static public func startGCDProxy(){
        SocketManager.shared.startGCDServer()
    }
    static public func stopGCDProxy(){
        
    }
    static public func reloadRule(_ path:String){
    }
    static public func reloadProxy(){
    }
    
    
    
}

extension XProxy{
    static func log(_ msg:String,items: Any...,level:AxLoggerLevel , category:String="default",file:String=#file,line:Int=#line,ud:[String:String]=[:],tags:[String]=[],time:Date=Date()){
        
        if level != AxLoggerLevel.Debug {
            AxLogger.log(msg,level:level)
        }
        
    }
}
