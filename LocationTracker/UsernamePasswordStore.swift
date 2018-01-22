//
//  UsernamePasswordStore.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/6/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

struct UsernamePasswordStore {
    
    static let serviceName: String = "LocationTracker"
    static let usernameKey: String = "Username"
    
    
    // MARK: Save Members
    
    static func saveUsername(username: String) {
        UserDefaults.setValue(username, forKey: usernameKey)
        AppState.username = username
    }
    
    static func savePassword(password: String, username: String) {
        deletePassword(username: username)
        //
        let keychainQuery: [NSObject: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService : serviceName as AnyObject,
            kSecAttrAccount : username as AnyObject,
            kSecValueData: password.data(using: String.Encoding.utf8)! as AnyObject
        ]
        let status: OSStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
        if (status == errSecSuccess) {
            AppState.password = password
        }
    }
    
    static func saveUsernamePassword(username: String, password: String) {
        self.saveUsername(username: username)
        self.savePassword(password: password, username: username)
    }
    
    // MARK: Load Members
    
    static func loadUsername() -> String? {
        if (AppState.username == nil) {
            let defaults = UserDefaults.standard
            AppState.username = defaults.value(forKey: usernameKey) as? String
        }
        return AppState.username;
    }
    
    static func loadPassword(username: String) -> String? {
        if (AppState.password == nil) {
            // load from keychain
            let keychainQuery: [NSObject: AnyObject] =  [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : serviceName as AnyObject,
                kSecAttrAccount : username as AnyObject,
                kSecReturnData : kCFBooleanTrue,
                kSecMatchLimit : kSecMatchLimitOne]
            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
            if status == errSecSuccess, let retrievedData = dataTypeRef as! NSData? {
                AppState.password = NSString(data: retrievedData as Data, encoding: String.Encoding.utf8.rawValue) as String?
            }
        }
        return AppState.password
    }
    
    // MARK: Delete Members
    
    static func deleteUsernamePassword() {
        if (AppState.username != nil) {
            deletePassword(username: AppState.username!)
        }
        deleteUsername()
    }
    
    static func deleteUsername() {
        UserDefaults.standard.setValue(nil, forKey: usernameKey)
        AppState.username = nil
    }
    
    static func deletePassword(username: String) {
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName as AnyObject,
            kSecAttrAccount: username as AnyObject,
            kSecReturnData: kCFBooleanTrue,
            kSecMatchLimit: kSecMatchLimitOne]
        SecItemDelete(keychainQuery as CFDictionary)
    }
}
