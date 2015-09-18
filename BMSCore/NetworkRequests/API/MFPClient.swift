//
//  MFPClient.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/17/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


internal protocol MFPClient {
    
    /**
     *  Specifies default request timeout.
     */
    var requestTimeout: Int { get set }
    
    var challengeHandler: [String: Any] { get }
    
    
    /**
     *  Registers a delegate that will handle authentication for the specified realm
     *
     *  @param delegate The delegate that will handle authentication challenges
     *  @param forRealm The realm name
     */
    func registerAuthenticationDelegate(delegate: Any, realm: String)
    
    /**
     *  Unregisters an authentication delegate for the specified realm
     *
     *  @param realm Realm name
     */
    func unregisterAuthenticationHandler()
    
}


internal extension MFPClient {
    
    func registerAuthenticationDelegate(delegate: Any, realm: String) {
        
    }
    
    func unregisterAuthenticationHandler() {
        
    }
    
}