/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController {
    @IBOutlet var loginOrSignup: UIButton!
    @IBOutlet var changeMode: UIButton!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var riderLabel: UILabel!
    @IBOutlet var driverLabel: UILabel!
    @IBOutlet var riderOrDriver: UISwitch!
    @IBOutlet var passwordText: UITextField!
    @IBOutlet var userText: UITextField!
    
    var signupMode = true
    var activityIndicator = UIActivityIndicatorView()

    
    func createAlert(title: String, message: String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler:{(action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func changeMode(_ sender: Any) {
        if signupMode{
            //Log In Mode
            messageLabel.text = "Don't have an account?"
            changeMode.setTitle("Sign Up", for: [])
            loginOrSignup.setTitle("Log In", for: [])
            riderOrDriver.isHidden = true
            riderLabel.isHidden = true
            driverLabel.isHidden = true
            signupMode = false
            
        }else{
            
            //Sign Up Mode
            messageLabel.text = "Already have an account?"
            changeMode.setTitle("Log In", for: [])
            loginOrSignup.setTitle("Sign Up", for: [])
            riderOrDriver.isHidden = false
            riderLabel.isHidden = false
            driverLabel.isHidden = false
            signupMode = true
        }
    }
    
    @IBAction func loginOrSignup(_ sender: Any) {
        if userText.text != "" || passwordText.text != ""{
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            UIApplication.shared.beginIgnoringInteractionEvents()
            
            if signupMode{
                //Sign Up
                let user = PFUser()
                user.username = userText.text
                user.password = passwordText.text
                user["isDriver"] = riderOrDriver.isOn
                
                user.signUpInBackground{(success, error) in
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    var displayErrorMessage = "Please try again later"
                    if error != nil{
                        if let errorMessage = (error! as NSError).userInfo["error"] as? String{
                            displayErrorMessage = errorMessage
                        }
                        self.createAlert(title: "Sign Up Error", message: displayErrorMessage)
                    }else{
                        print("User signed up")
                        
                        if let isDriver = PFUser.current()?["isDriver"] as? Bool{
                            if isDriver{
                                self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                                
                            }else{
                                self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                            }
                        }
                    }
                }
            }else{
                //Log In
                PFUser.logInWithUsername(inBackground: self.userText.text!, password: self.passwordText.text!, block: {(user, error) in
                    
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    if error != nil{
                        
                        var displayErrorMessage = "Please try again later"
                        if let errorMessage = (error! as NSError).userInfo["error"] as? String{
                            displayErrorMessage = errorMessage
                        }
                        self.createAlert(title: "Log In Error", message: displayErrorMessage)
                        
                    }else{
                        
                        print("Logged In")
                        
                        if let isDriver = PFUser.current()?["isDriver"] as? Bool{
                            if isDriver{
                                self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                            }else{
                                self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                            }
                        }
                    }
                })
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let thisID = PFUser.current()?.objectId as? String{
            print(thisID)
            if let isDriver = PFUser.current()?["isDriver"] as? Bool{
                if isDriver{
                    self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                }else{
                    self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
