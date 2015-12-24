//
//  AuthorizationManagerProtocol.swift
//  BMSCore
//
//  Created by Ilan Klein on 24/12/2015.
//  Copyright © 2015 IBM. All rights reserved.
//

public protocol AuthorizationManagerProtocol {
    func isAuthorizationRequired(statusCode: Int, responseAuthorizationHeader: String) -> Bool
    func isAuthorizationRequired(httpResponse: NSHTTPURLResponse) -> Bool
//    init()
//    func isOAuthError(response: Response?) -> Bool//    func clearAuthorizationData()
//    func addCachedAuthorizationHeader(request: NSMutableURLRequest)
//    func getCachedAuthorizationHeader() -> String?
//    func obtainAuthorizationHeader(completionHandler: MfpCompletionHandler)
//    
//    func getUserIdentity() -> AnyObject?
//    
//    func getDeviceIdentity() -> AnyObject?
//    func getAppIdentity() -> AnyObject?
//    func getAuthorizationPersistencePolicy() -> PersistensePolicy
}
