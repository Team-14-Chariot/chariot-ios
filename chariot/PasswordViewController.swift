//
//  PasswordViewController.swift
//  chariot
//
//  Created by Reese Crowell on 11/28/22.
//

import UIKit

class PasswordViewController: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // make api call for password
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let event_code = appDelegate.eventID
        let password = (self.passwordField.text ?? "") as String
        
        let parameters: [String: Any] = [
            "event_id": event_code,
            "driver_password": password
        ]
       

        let url = URL(string: "https://chariot.augustabt.com/api/validateDriverPassword")!
       
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

                semaphore.signal()
            }
        }.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
    
        print("resp")
        print(resp)
        
        if (resp == 200) {
            return true
        } else {
            let alert = UIAlertController(title: "Error Joining Event", message: "Password entered was incorrect.", preferredStyle: .alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.cancel))
            // show the alert
            self.present(alert, animated: true, completion: nil)
            return false
        }
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? DetailsEntryViewController {
            //            pass rider name and eventually image here
            vc.hasPassword = true
            vc.password = self.passwordField.text ?? ""
        }
        
    }
    

}
