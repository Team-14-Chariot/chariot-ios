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
//             //                    print(data)
//             do {
//             let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
//             self.driverID = (json["driver_id"] as? String)!
//             print(json["driver_id"])
//
//             } catch let error as NSError {
//             print(error)
//             }
             
             //                    self.driverID = data["driver_id"]
             self.responseCode = resp
             semaphore.signal()
             }
             }.resume()
             _ = semaphore.wait(timeout: .distantFuture)
             
             print("self.responseCode")
             print(self.responseCode)
             print("resp")
             print(resp)
             
             return self.responseCode == 200
             }
             
             return false // this neeeds to be false after I uncomment it
             
    }
    
    
    //
}
