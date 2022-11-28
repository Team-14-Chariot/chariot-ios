//
//  EventViewController.swift
//  chariot
//
//  Created by Reese Crowell on 10/1/22.
//

import UIKit

class EventViewController: UIViewController {
    
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var event_code: UITextField!
    
    var driverID = ""
    var responseCode = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true);
        
//        event_code.borderStyle = UITextField.BorderStyle.roundedRect
        self.event_code.layer.cornerRadius = (self.event_code.frame.height / 2)
        self.event_code.clipsToBounds = true

        // Do any additional setup after loading the view.
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        var resp = 0
        
        let parameters: [String: Any] = [
        "event_id": String(event_code.text!)
        ]
       
       let appDelegate = UIApplication.shared.delegate as! AppDelegate
       appDelegate.eventID = String(event_code.text!)
        // the working stuff
        let url = URL(string: "https://chariot.augustabt.com/api/validateEvent")!
       
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
        return
        }
        let jsonString = String(data: httpBody, encoding: .utf8)
        print(jsonString!)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let _ = data, let response = response as? HTTPURLResponse {
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                print(resp)

                self.responseCode = resp
                semaphore.signal()
            }
        }.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        print("self.responseCode")
        print(self.responseCode)
        print("resp")
        print(resp)
        
       if (self.responseCode > 299) {
           // TODO: make a popup to ask if you want to get ride if no go to pause screen
           let alert = UIAlertController(title: "Error Joining Event", message: "Check to make sure your Event Code is correct.", preferredStyle: .alert)
           // add an action (button)
           alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.cancel))
           // show the alert
           self.present(alert, animated: true, completion: nil)
       }
        if (self.responseCode == 200) {
            let viewController:
            UIViewController = UIStoryboard(
                name: "detailsID", bundle: nil).instantiateViewController(withIdentifier: "detailsID") as UIViewController
            self.present(viewController, animated: false)
        }
        //FIX WITH WHATEVER VALUE IS PASSWORD EVENT
        if (self.responseCode == 0) {
            let viewController:
            UIViewController = UIStoryboard(
                name: "passwordID", bundle: nil).instantiateViewController(withIdentifier: "passwordID") as UIViewController
            self.present(viewController, animated: false)
        }
    }
    /*
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//        return true
        
        if identifier == "toDetails" {
            
             var resp = 0
             
             let parameters: [String: Any] = [
             "event_id": String(event_code.text!)
             ]
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.eventID = String(event_code.text!)
             // the working stuff
             let url = URL(string: "https://chariot.augustabt.com/api/validateEvent")!
            
             var request = URLRequest(url: url)
             request.httpMethod = "POST"
             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
             guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
             return false
             }
             let jsonString = String(data: httpBody, encoding: .utf8)
             print(jsonString!)
             request.httpBody = httpBody
             request.timeoutInterval = 20
             
             let semaphore = DispatchSemaphore(value: 0)
             
             let session = URLSession.shared
             session.dataTask(with: request) { (data, response, error) in
                 if error == nil, let _ = data, let response = response as? HTTPURLResponse {
                     print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                     print("statusCode: \(response.statusCode)")
                     resp = response.statusCode
                     print(resp)

                     self.responseCode = resp
                     semaphore.signal()
                 }
             }.resume()
             _ = semaphore.wait(timeout: .distantFuture)
             
             print("self.responseCode")
             print(self.responseCode)
             print("resp")
             print(resp)
             
            if (self.responseCode != 200) {
                // TODO: make a popup to ask if you want to get ride if no go to pause screen
                let alert = UIAlertController(title: "Error Joining Event", message: "Check to make sure your Event Code is correct.", preferredStyle: .alert)
                // add an action (button)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.cancel))
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            
             return self.responseCode == 200
             }
             
             return false // this neeeds to be false after I uncomment it
             
    }
    */
    
    //
}
