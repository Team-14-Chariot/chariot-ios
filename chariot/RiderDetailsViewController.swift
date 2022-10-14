//
//  RiderDetailsViewController.swift
//  chariot
//
//  Created by Reese Crowell on 10/12/22.
//

import UIKit

class RiderDetailsViewController: UIViewController {

    @IBOutlet weak var riderNameLabel: UILabel!
    var riderName: String=""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.riderNameLabel.text = self.riderName
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

}
