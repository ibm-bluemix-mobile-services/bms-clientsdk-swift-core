//
//  BMSResponse.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/17/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


public struct BMSResponse: Response, CustomStringConvertible {
    
    
    // MARK: Properties (public)
    
    public let description: String
    
    public let status: String
    
    public let headers: [String: String]
    
    public let responseText: String
    
    public let responseJSON: [String: AnyObject]
    
    public let responseData: NSData
    
    public let error: ErrorType?
    
    
    
    // MARK: Properties (internal/private)
    
    private let alamoFireResponse: NSHTTPURLResponse
    
    let isRedirect: Bool
    
    let isSuccessful: Bool
    
    
    
    // MARK: Initializer
    
    // TODO: Implement initializer
//    init() {
//        
//    }
    
}
