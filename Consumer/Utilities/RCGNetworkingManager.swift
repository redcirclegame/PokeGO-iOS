//
//  RCGNetworkingManager.swift
//  Consumer
//
//  Created by Vlad Zagorodnyuk on 7/13/16.
//  Copyright © 2016 Vlad Z. All rights reserved.
//

import UIKit

import Alamofire
import PromiseKit
import SwiftyJSON
import EZSwiftExtensions

let hostName = "http://pokeapi.co/api/v2"

public let RCGNetworkingManagerLoginFailureNotificationKey = "RCGNetworkingManagerLoginFailureNotificationKey"
public let RCGNetworkingManagerLoginSuccessfulNotificationKey = "RCGNetworkingManagerLoginSuccessfulNotificationKey"
public let RCGNetworkingManagerLogoutSuccessfulNotificationKey = "RCGNetworkingManagerLogoutSuccessfulNotificationKey"
public let RCGNetworkingManagerRequestUnauthorizedNotificationKey = "RCGNetworkingManagerRequestUnauthorizedNotificationKey"

class RCGNetworkingManager: NSObject {

    // Setting header check
    private var isHeaderSet = false
    
    var headers = [
        "Content-Type": "application/json"
    ]
    
    static let sharedManager = RCGNetworkingManager()
    
    let manager = Alamofire.Manager(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    
    // MARK: - http requests
    
    // GET Request
    
    func GET(URLPath: String, parameters: [String: AnyObject]?, success: (response: JSON?)-> Void, failure: (error: NSError)-> Void) {
        
        self.request(.GET, URLPath, parameters: parameters, success: { (response) in
            success(response: response)
        }) { (error) in
            failure(error: error)
        }
    }
    
    // POST Request
    
    func POST(URLPath: String, parameters: [String: AnyObject]?, success: (response: JSON?)-> Void, failure: (error: NSError)-> Void) {
        
        self.request(.POST, URLPath, parameters: parameters, success: { (response) in
            success(response: response)
        }) { (error) in
            failure(error: error)
        }
    }
    
    // PATCH Request
    
    func PATCH(URLPath: String, parameters: [String: AnyObject]?, success: (response: JSON?)-> Void, failure: (error: NSError)-> Void) {
        self.request(.PATCH, URLPath, parameters: parameters, success: { (response) in
            success(response: response)
        }) { (error) in
            failure(error: error)
        }
    }
    
    // Put Request
    
    func PUT(URLPath: String, parameters: [String: AnyObject]?, success: (response: JSON?)-> Void, failure: (error: NSError)-> Void) {
        self.request(.PUT, URLPath, parameters: parameters, success: { (response) in
            success(response: response)
        }) { (error) in
            failure(error: error)
        }
    }
    
    // Delete Request
    
    func DELETE(URLPath: String, parameters: [String: AnyObject]?, success: (response: JSON?)-> Void, failure: (error: NSError)-> Void) {
        self.request(.DELETE, URLPath, parameters: parameters, success: { (response) in
            success(response: response)
        }) { (error) in
            failure(error: error)
        }
    }
    
    // Promise GET Request
    
    func GET(URLPath: String, parameters: [String: AnyObject]?, encoding: ParameterEncoding = .JSON)-> Promise<JSON> {
        
        return self.request(.GET, URLPath, parameters: parameters, encoding: encoding)
    }
    
    // Promise POST Request
    
    func POST(URLPath: String, parameters: [String: AnyObject]?)-> Promise<JSON> {
        
        return self.request(.POST, URLPath, parameters: parameters)
    }
    
    func POST(URLPath: String, parameters: [String: AnyObject]?, encoding: ParameterEncoding)-> Promise<JSON> {
        
        return self.request(.POST, URLPath, parameters: parameters, encoding: encoding)
    }
    
    // Promise PATCH Request
    
    func PATCH(URLPath: String, parameters: [String: AnyObject]?)-> Promise<JSON> {
        
        return self.request(.PATCH, URLPath, parameters: parameters)
    }
    
    // Promise PUT Request
    
    func PUT(URLPath: String, parameters: [String: AnyObject]?)-> Promise<JSON> {
        
        return self.request(.PUT, URLPath, parameters: parameters)
    }
    
    // Promise DELETE Request
    
    func DELETE(URLPath: String, parameters: [String: AnyObject]?)-> Promise<JSON> {
        
        return self.request(.DELETE, URLPath, parameters: parameters)
    }
    
    func DELETE(URLPath: String, parameters: [String: AnyObject]?, encoding: ParameterEncoding)-> Promise<JSON> {
        
        return self.request(.DELETE, URLPath, parameters: parameters, encoding: encoding)
    }
    
    func baseUrl() -> String {
        
        return String(format: "https://%@", hostName)
    }
    
    func URLStringWithPath(path: String)-> String {
        
        return hostName + path
    }
    
    // MARK: - Promises
    // Logout logic
    
    func promiseLogout() -> Promise<AnyObject?> {
        
        return Promise { fulfill, reject in
            
            let appDomain = NSBundle.mainBundle().bundleIdentifier
            NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
            
            self.clearAllCookies()
            
            let nc = NSNotificationCenter.defaultCenter()
            nc.postNotificationName(RCGNetworkingManagerLogoutSuccessfulNotificationKey, object: nil)
            
            fulfill(nil)
        }
    }
    
    // MARK: - Notification
    
    func postUnauthorizedResponseNotification() {
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(RCGNetworkingManagerRequestUnauthorizedNotificationKey, object: nil)
    }
    
    // MARK: - Cookies, yum
    
    func clearAllCookies() {
        
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        
        if storage.cookies != nil {
            for cookie in storage.cookies! {
                
                let domainName = cookie.domain
                let domainRange = domainName.rangeOfString(hostName)
                
                if domainRange?.count > 0 {
                    
                    storage.deleteCookie(cookie)
                }
            }
        }
    }
    
    // Utility Methods
    
    private func request(method: Alamofire.Method, _ URLString: String, parameters: [String: AnyObject]?, success: (response: JSON?)-> Void, failure: (error: NSError)-> Void) {
        
        self.request(method, URLString, parameters: parameters, encoding: .JSON, success: { response in
            success(response: response)
            }) { error in
                failure(error: error)
        }
    }
    
    private func request(method: Alamofire.Method, _ URLString: String, parameters: [String: AnyObject]?, encoding: ParameterEncoding, success: (response: JSON?)-> Void, failure: (error: NSError)-> Void) {
        
        self.manager.request(method, self.URLStringWithPath(URLString), parameters: parameters, encoding: encoding, headers: headers)
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let json = JSON(value)
                        success(response: json)
                    }
                case .Failure(let error):
                    
                    failure(error: error)
                }
        }
    }
    
    // Promise Requests + static data
    
    private func request(method: Alamofire.Method, _ URLString: String, parameters: [String: AnyObject]?, encoding: ParameterEncoding)-> Promise<JSON> {
        
//        let url = self.URLStringWithPath(URLString)
        
        let url = NSURL(string: URLString)
        
        return Promise { fulfill, reject in
            self.manager.request(method, url!, parameters: nil, encoding: encoding, headers: headers)
                .validate()
                .responseJSON { response in
                    
                    switch response.result {
                        
                    case .Success:
                        if let value = response.result.value as? [String: AnyObject] {
                            
                            guard let _jsonDict = JSON(value).dictionary else {
                                fulfill(nil)
                                return
                            }
                            
                            fulfill(JSON(_jsonDict))
                        }
                        
                    case .Failure(let error):
                        
                        reject(error)
                    }
            }
        }
    }
    
    private func request(method: Alamofire.Method, _ URLString: String, parameters: [String: AnyObject]?)-> Promise<JSON> {
        
        return self.request(method, URLString, parameters: parameters, encoding: .JSON)
    }
}
