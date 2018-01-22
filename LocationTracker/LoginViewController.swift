//
//  LoginViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/4/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // clear username/password fields
        self.usernameTextField.text = ""
        self.passwordTextField.text = "";
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // automatically log in if username/password exist
        let username = UsernamePasswordStore.loadUsername()
        if (username != nil) {
            let password = UsernamePasswordStore.loadPassword(username: username!)
            if (password != nil) {
                let apiKey = LocationDbInfoStore.loadApiKey()
                if (apiKey != nil) {
                    let apiPassword = LocationDbInfoStore.loadApiPassword(apiKey: apiKey!)
                    if (apiPassword != nil) {
                        LocationDbInfoStore.loadDbHost()
                        LocationDbInfoStore.loadDbName()
                        self.performSegue(withIdentifier: "ShowMap", sender: self)
                    }
                }
                // TODO: if online - login again???
                //login(username!, password: password!)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonPressed(sender: UIButton) {
        self.login(username: self.usernameTextField.text!, password: self.passwordTextField.text!)
    }
    
    @IBAction func registerButtonPressed(sender: UIButton) {
        self.performSegue(withIdentifier: "ShowRegisterViewController", sender: self)
    }
    
    func login(username: String, password: String) {
        self.showActivityIndicator()
        let url = NSURL(string: "\(AppConstants.baseUrl)/api/login")
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url! as URL)
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.addValue("application/json", forHTTPHeaderField:"Accepts")
        request.httpMethod = "POST"
        request.httpBody = self.getLoginHttpBody(username: username, password: password) as Data
        //
        let task = session.dataTask(with: request as URLRequest) {
            ( data, response, error) in
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
        self.loginButton.isHidden = true
        self.activityIndicator.isHidden = false
    }
    
    func hideActivityIndicatory() {
        self.activityIndicator.isHidden = true
        self.loginButton.isHidden = false
        self.view.isUserInteractionEnabled = true
    }
    
    func showLoginErrorDialog() {
        let alert = UIAlertController(title:"Login Error", message:"Error logging in.", preferredStyle:UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.default, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
}
