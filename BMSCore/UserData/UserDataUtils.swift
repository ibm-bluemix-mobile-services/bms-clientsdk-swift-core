//
//  sharedPreferencesManager.swift
//  BMSCore
//
//  Created by Oded Betzalel on 12/29/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation

public class UserDataUtils {
    
    public var sharedPreferences:NSUserDefaults
    public var stringEncryption:StringEncryption?
    
    public init() {
        //TODO:check that this is indeed the correct thing to do here
        self.sharedPreferences = NSUserDefaults.standardUserDefaults()
        self.stringEncryption = nil
    }
    
    internal func setStringEncryption(stringEncryption:StringEncryption) {
        self.stringEncryption = stringEncryption;
    }
}

/**
 * Holds single string preference value
 */
public class StringPreference {
    
    var prefName:String;
    var value:String?;
    var userDataUtils:UserDataUtils
    
    public convenience init(prefName:String, userDataUtils:UserDataUtils) {
        self.init(prefName: prefName, defaultValue: nil, userDataUtils:userDataUtils)
    }
    
    public init(prefName:String, defaultValue:String?, userDataUtils:UserDataUtils) {
        self.prefName = prefName;
        self.userDataUtils = userDataUtils
        if let val = userDataUtils.sharedPreferences.valueForKey(prefName) as? String {
            self.value = val
        } else {
            self.value = defaultValue
        }
    }
    
    public func get() ->String?{
        if let value = value, encryptedValue = self.userDataUtils.stringEncryption?.decrypt(value){
            return encryptedValue
        } else {
            return nil
        }
    }
    
    public func set(value:String?) {
        if let value = value, encryptedValue = self.userDataUtils.stringEncryption?.encrypt(value){
            self.value = encryptedValue
        } else {
            self.value = nil
        }
        commit();
    }
    
    public func clear() {
        self.value = nil;
        commit()
    }
    
    private func commit() {
        self.userDataUtils.sharedPreferences.setValue(value, forKey: prefName)
        self.userDataUtils.sharedPreferences.synchronize()
    }
}

/**
 * Holds single JSON preference value
 */
public class JSONPreference:StringPreference {
    
    public init(prefName:String, userDataUtils:UserDataUtils) {
        super.init(prefName: prefName, defaultValue: nil, userDataUtils:userDataUtils)
    }
    
    public func set(json:[String:AnyObject])
    {
        set(String(json))
    }

    public func getAsMap() -> [String:AnyObject]?{
        do {
            if let data = get()?.dataUsingEncoding(NSUTF8StringEncoding) {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject]
            }
        } catch {
            //TODO: handle error
            return nil
        }
        return nil
    }
}