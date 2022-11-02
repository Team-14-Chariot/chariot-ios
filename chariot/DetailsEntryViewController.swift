//
//  DetailsEntryViewController.swift
//  chariot
//
//  Created by Reese Crowell on 10/21/22.
//

import UIKit

class DetailsEntryViewController: UIViewController {


    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var plateField: UITextField!
    
    @IBOutlet weak var capacityField: UITextField!
    
    @IBOutlet weak var descriptionField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func onSubmit(_ sender: Any) {
        
        let name : String = nameField.text ?? "no_name"
        let capacity : Int = Int(capacityField.text!) ?? 3
        let plate : String = plateField.text ?? ""
        let description : String = descriptionField.text ?? ""
        
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let eventID: String = appDelegate.eventID
        let parameters: [String: Any] = [
            "event_id": eventID,
            "driver_id": myDriverID,
            "name": name,
            "car_capacity": capacity,
            "car_license_plate": plate,
            "car_description": description
        ]
        //TODO: fix url
        let url = URL(string: "https://chariot.augustabt.com/api/joinEvent")!
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
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let _ = data, let response = response as? HTTPURLResponse {
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                print(resp)
            }
        }.resume()
        
        
        performSegue(withIdentifier: "toMainDisplay", sender: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
