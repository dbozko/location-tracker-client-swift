//
//  RegisterViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/4/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func registerButtonPressed(sender: UIButton) {
        self.register(username: self.usernameTextField.text!, password: self.passwordTextField.text!)
    }

    func register(username: String, password: String) {
        self.showActivityIndicator()
        
        let _id = self.usernameTextField.text!
        let url = NSURL(string: "\(AppConstants.baseUrl)/api/users/\(_id)")
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url! as URL)
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.addValue("application/json", forHTTPHeaderField:"Accepts")
        request.httpMethod = "PUT"
        request.httpBody = self.getRegisterHttpBody(_id: _id) as Data
        
        let task = session.dataTask(with: request as URLRequest) {
            ( data, response, error) in
            OperationQueue.main.addOperation {
                guard let _:NSData = data as! NSData, let _:URLResponse = response, error == nil else {
                    self.hideActivityIndicatory()
                    self.showRegiterErrorDialog(statusCode: 0)
                    return
                }
                var dict: NSDictionary!
                do {
                    dict = try JSONSerialization.jsonObject(with: data!, options:[]) as? NSDictionary
                }
                catch {
                    print(error)
                }
                if (dict != nil && (dict["ok"] as? Bool) == true) {
                    self.login(username: username, password: password)
                }
                else {
                    self.hideActivityIndicatory()
                    self.showRegiterErrorDialog(statusCode: (response as! HTTPURLResponse).statusCode)
                }
            }
            
        }
        
        task.resume()
    }
    
    func getRegisterHttpBody(_id:String) -> NSData {
        var params: [String:String] = [String:String]()
        params["username"] = self.usernameTextField.text
        params["password"] = self.passwordTextField.text
        params["type"] = "user"
        params["_id"] = _id
        var body: NSData!
        do {
            body = try JSONSerialization.data(withJSONObject: params as NSDictionary, options: []) as NSData
        }
        catch {
            print(error)
        }
        return body
    }
    
    func login(username: String, password: String) {
        let url = NSURL(string: "\(AppConstants.baseUrl)/api/login")
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url! as URL)
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.addValue("application/json", forHTTPHeaderField:"Accepts")
        request.httpMethod = "POST"
        request.httpBody = self.getLoginHttpBody(username: username, password: password) as Data
        //
        let task = session.dataTask(with: request as URLRequest) {
            (data, response, error) in
            OperationQueue.main.addOperation {
                guard let _:NSData = data as! NSData, let _:URLResponse = response, error == nil else {
                    self.hideActivityIndicatory()
                    self.showLoginErrorDialog()
                    return
                }
                var dict: NSDictionary!
                do {
                    dict = try JSONSerialization.jsonObject(with: data!, options:[]) as? NSDictionary
                }
                catch {
                    print(error)
                }
                if (dict != nil && (dict["ok"] as? Bool) == true) {
                    UsernamePasswordStore.saveUsernamePassword(username: username, password: password)
                    LocationDbInfoStore.saveApiKeyPasswordDbNameHost(
                        apiKey: dict["api_key"] as! String,
                        apiPassword: dict["api_password"] as! String,
                        dbName: dict["location_db_name"] as! String,
                        dbHost: dict["location_db_host"] as! String,
                        dbHostProtocol: dict["location_db_host_protocol"] as? String
                    )
                    self.hideActivityIndicatory()
                    self.performSegue(withIdentifier: "ShowMap", sender: self)
                }
                else {
                    self.hideActivityIndicatory()
                    self.showLoginErrorDialog()
                }
            }
        }
        //
        task.resume()
    }
    
    func getLoginHttpBody(username: String, password: String) -> NSData {
        var params: [String:String] = [String:String]()
        params["username"] = username
        params["password"] = password
        var body: NSData!
        do {
            body = try JSONSerialization.data(withJSONObject: params as NSDictionary, options: []) as NSData
        }
        catch {
            print(error)
        }
        return body
    }
    
    func showActivityIndicator() {
        self.view.isUserInteractionEnabled = false
        self.registerButton.isHidden = true
        self.activityIndicator.isHidden = false
    }
    
    func hideActivityIndicatory() {
        self.activityIndicator.isHidden = true
        self.registerButton.isHidden = false
        self.view.isUserInteractionEnabled = true
    }
    
    func showRegiterErrorDialog(statusCode: Int) {
        var message = "Error registering."
        if (statusCode == 409) {
            message += " User already exists."
        }
        let alert = UIAlertController(title:"Register Error", message:message, preferredStyle:UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.default, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showLoginErrorDialog() {
        let alert = UIAlertController(title:"Login Error", message:"Error logging in.", preferredStyle:UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.default, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }

}
