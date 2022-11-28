//
//  RiderQueueViewController.swift
//  chariot
//
//  Created by Reese Crowell on 11/28/22.
//

import UIKit

class RiderQueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var riders = [[String:Any]]()
    var refreshControl = UIRefreshControl()

 
    func fetchRiderQueue() {
        // post request for getting ride
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let parameters: [String: Any] = [
            "driver_id": myDriverID
        ]
        // FIX URL
        let url = URL(string: "https://chariot.augustabt.com/api/resumeDriver")!
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
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                print(resp)
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                    self.riders = json["queue"] as! [[String:Any]]
                    
                } catch let error as NSError {
                    print(error)
                }
            }
        }.resume()
    }
    
    @objc func refresh(_ sender: AnyObject) {
       // Code to refresh table view
        // Code to refresh table view
         fetchRiderQueue()
         tableView.reloadData()
         
         self.refreshControl.endRefreshing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
           refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
           tableView.addSubview(refreshControl) // not required when using UITableViewController

        // network request to generate the values for table here
        fetchRiderQueue()
        
        tableView.reloadData()
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return number of riders in queue, get length of array
        return riders.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // make each cell using this format
        let cell = tableView.dequeueReusableCell(withIdentifier: "RiderCell") as! RiderCell
        
        let name = "" //get name from json
        let pickup = "" //get pickup address
        let dropoff = "" //get dropoff from json

        cell.riderName.text = name
        cell.pickupAddress.text = pickup
        cell.dropoffAddress.text = dropoff
        
        return cell
        
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
