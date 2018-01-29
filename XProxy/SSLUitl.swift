//
//  SSLUitl.swift
//  XProxy
//
//  Created by yarshure on 2018/1/29.
//  Copyright © 2018年 yarshure. All rights reserved.
//

import Foundation
import Security
public func copyPublicKey(caCertificate:SecCertificate) ->SecKey?
{
    var caPublicKey:SecKey?
    if #available(iOSApplicationExtension 10.3, *) {
        #if os(macOS)
            SecCertificateCopyPublicKey(caCertificate, &caPublicKey)
        #elseif os(iOS)
            caPublicKey = SecCertificateCopyPublicKey(caCertificate)
        #endif
    } else {
        
    }
    return caPublicKey
}

public func copyOID(certificate:SecCertificate ) ->NSDictionary{
    #if os(macOS)
        return SecCertificateCopyValues(certificate, nil, nil)!
    #else
        return [:]
    #endif
}
