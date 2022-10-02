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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {

        if identifier == "toMainDisplay" {
            // here is where I would query the backend for valid event
            // want to be able to pass event name to next screen ?

            if event_code.text == "pdt" {
                return true
            }
        }

        return false
    }

}
