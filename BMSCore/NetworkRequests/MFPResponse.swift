//
//  BMSResponse.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/17/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


public struct MFPResponse: Response {
    
    
    // MARK: Properties (public)
    
    public let statusCode: Int?
    
    public let headers: [NSObject: AnyObject]?
    
    public let responseText: String?
    
    public let responseJSON: AnyObject?
    
    public let responseData: NSData?
    
    
    
    // MARK: Properties (internal/private)
    
    let alamoFireResponse: NSHTTPURLResponse?
    
    let isSuccessful: Bool?
    
    let isRedirect: Bool
    
    
    
    // MARK: Initializer
    
    init(responseText: String?, responseJSON: AnyObject?, responseData: NSData?, alamoFireResponse: NSHTTPURLResponse?, isRedirect: Bool) {
        
        self.responseText = responseText
        self.responseJSON = responseJSON
        self.responseData = responseData
        self.alamoFireResponse = alamoFireResponse
        self.isRedirect = isRedirect
        
        self.statusCode = alamoFireResponse?.statusCode
        
        if let status = statusCode {
            isSuccessful = (200..<300 ~= status)
        }
        else {
            isSuccessful = false
        }
        
        self.headers = alamoFireResponse?.allHeaderFields
    }
    
}
