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

        // Do any additional setup after loading the view.
    }
    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {

        if identifier == "startToMain" {
            var resp = 0
            // here is where I would query the backend for valid event
            // want to be able to pass event name to next screen ?

            // chariot.augustabt.com/api/joinEvent
            //eventId:
            //name:
            //carDescription:
            //car_liscence_plate:
//            struct eventParams: Codable {
//                var event_id: String
//                var name: String?
//                var car_capacity: Int?
//                var car_description: String?
//                var car_liscence_plate: String?
//            }
            
            let parameters: [String: Any] = [
                "event_id": String(event_code.text!),
                "name": "Test Driver",
                "car_capacity": 3,
                "car_description": "short description",
                "car_liscence_plate": "YCQ118"
            ]
//            let params = eventParams(event_id: String(event_code.text!), name: "Test", car_capacity: 3, car_description: "nope", car_liscence_plate: "YCQ118")
//

            
            // the working stuff
            let url = URL(string: "https://chariot.augustabt.com/api/joinEvent")!
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
                if error == nil, let data = data, let response = response as? HTTPURLResponse {
                    print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                    print("statusCode: \(response.statusCode)")
                    resp = response.statusCode
                    print(resp)
//                    print(data)
                    do {
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                        self.driverID = (json["driver_id"] as? String)!
                        print(json["driver_id"])
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.driverID = (json["driver_id"] as? String)!
                        } catch let error as NSError {
                            print(error)
                        }
                    
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

        return false
    }
    
    
//
}
