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


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true);

        // Do any additional setup after loading the view.
    }
    
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    /*
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {

        if identifier == "startToMain" {
            // here is where I would query the backend for valid event
            // want to be able to pass event name to next screen ?

            // chariot.augustabt.com/api/joinEvent
            //eventId:
            //name:
            //carDescription:
            //car_liscence_plate:
            let parameters: [String: Any] = [
                "eventId": event_code.text,
                "name": "Test Driver",
                "carDescription": "short description",
                "car_liscence_plate": "YCQ118"
                    ]
            
            let url = URL(string: "chariot.augustabt.com:8090/api/joinEvent")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                    return false
                }
                request.httpBody = httpBody
                request.timeoutInterval = 20
                let session = URLSession.shared
                session.dataTask(with: request) { (data, response, error) in
                    if let response = response {
                        print(response)
                    }
                    if let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data, options: [])
                            print(json)
                        } catch {
                            print(error)
                        }
                    }
                }.resume()
            
//            if event_code.text == "pdt" {
//                return true
//            }
            return true;
        }

        return false
    }*/
//
}
