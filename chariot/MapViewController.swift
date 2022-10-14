//
//  MapViewController.swift
//  chariot
//
//  Created by Reese Crowell on 10/1/22.
//

import UIKit

import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var nextTurnLabel: UILabel!
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var riderInfoButton: UIButton!
    
    @IBOutlet weak var endSessionButton: UIBarButtonItem!
    @IBOutlet weak var pauseSessionButton: UIBarButtonItem!
    
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    private var riderLocation: CLPlacemark?
    private var riderDestination: CLPlacemark?
    
    enum status {
        case EMPTY, TO_PICKUP, TO_DEST
    }
    var currentStatus = status.EMPTY
    
    private var route: MKRoute?
    
    
    private var activeRide: Bool = false
    var ride_id: String = ""
    var rider_name: String = ""
    private var curDestination: MKMapItem?
    var waiting_for_ride: Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        nextTurnLabel.layer.cornerRadius = 8
        nextTurnLabel.clipsToBounds = true
        nextTurnLabel.isHidden = true
        
        testButton.layer.cornerRadius = testButton.frame.width / 2
        testButton.clipsToBounds = true
        testButton.isHidden = true
        
        riderInfoButton.layer.cornerRadius = riderInfoButton.frame.width/2
        riderInfoButton.clipsToBounds = true
        riderInfoButton.isHidden = true
        
        
        // To provide the shadow
        nextTurnLabel.layer.shadowRadius = 10
        nextTurnLabel.layer.shadowOpacity = 1.0
        nextTurnLabel.layer.shadowOffset = CGSize(width: 5, height: 5)
        nextTurnLabel.layer.shadowColor = UIColor.black.cgColor
        
        
        // Check for Location Services
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            //            locationManager.startUpdatingHeading()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        print("accepting Rides")
        //        turn on accepting rides here
        // post request for setting status to active
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let parameters: [String: Any] = [
            "driver_id": myDriverID
        ]
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
            if error == nil, let _ = data, let response = response as? HTTPURLResponse {
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                print(resp)
            }
        }.resume()
        
        // get Ride
        if activeRide == false {
            self.waiting_for_ride = true
            getRide()
        }
    }
    
    // MARK - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last
            let viewRegion = MKCoordinateRegion(center: locations.last!.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(viewRegion, animated: true)
            //            print("would be this often")
            // probably have to add this part to dropoff button
            // updates too slow to keep up with highway driving
            //            mapView.removeOverlays(self.mapView.overlays)
            
            if activeRide {
                if self.currentStatus == status.TO_PICKUP {
                    sendStatus(eta: self.generatePolyLine(toDestination: self.curDestination!))
                } else {
                    // on way to dropoff don't send real eta
                    _ = self.generatePolyLine(toDestination: self.curDestination!)
                    sendStatus(eta: 0)
                }
            } else {
                sendStatus(eta: 0)
            }
        }
        
        if currentLocation == nil {
            // Zoom to user location
            if  let userLocation = locations.last {
                let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                mapView.setRegion(viewRegion, animated: false)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.camera.heading = newHeading.magneticHeading
        mapView.setCamera(mapView.camera, animated: true)
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 5.0
            renderer.alpha = 0.5
            renderer.strokeColor = UIColor.blue
            
            return renderer
        }
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.lineWidth = 3.0
            renderer.alpha = 0.5
            renderer.strokeColor = UIColor.blue
            
            return renderer
        }
        return MKCircleRenderer()
    }
    
    func generatePolyLine(toDestination destination: MKMapItem) -> TimeInterval {
        
        let request = MKDirections.Request()
        //start from the user's current location to find the ride
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        
        directionRequest.calculate { response, error in
            if let error = error {
                print("Error calculating direction request \(error)")
            }
            guard let response = response else { return }
            self.route = response.routes.first
            guard let polyLine = self.route?.polyline else { return }
            self.mapView.addOverlay(polyLine, level: .aboveRoads)
            
            print("show steps? :")
            print(self.route!.steps[1].instructions)
            print(String(self.route!.steps[1].distance))
            
            self.nextTurnLabel.text = self.directionLabelString(instructions: self.route!.steps[1].instructions, meters: self.route!.steps[1].distance)
        }
        if self.route != nil {
            return self.route!.expectedTravelTime
        }
        return -1
    }
    
    func directionLabelString (instructions: String, meters: Double) -> String {
        let miles = meters / 1609
        return String(format: "%@ in %.2f miles", instructions, miles)//("\(instructions)\t \(miles, specifier: "%.2f")")
    }
    
    
    
    @IBAction func onTest(_ sender: Any) {
        //figure out how to navigate to a destination
        //        if rider in car -> destination
        if self.currentStatus == status.TO_DEST {
            // end current ride if one exists
            self.endRide()
            //            self.activeRide = false;
            
            //            testButton.setTitle("Accept Ride", for: .normal)
            while !mapView.overlays.isEmpty {
                mapView.removeOverlays(self.mapView.overlays)
                print("removed an overlay")
            }
            nextTurnLabel.isHidden = true
            riderInfoButton.isHidden = true
            testButton.isHidden = true
            //            make a new get ride request
            self.currentStatus = status.EMPTY
            self.waiting_for_ride = true
            self.getRide()
            
        } // this is on the way to rider, would press button now once you get to the rider
        else if self.currentStatus == status.TO_PICKUP {
            testButton.setTitle("Dropoff", for: .normal)
            // need to put address given here instead of default address
            
            self.curDestination = MKMapItem(placemark: MKPlacemark(placemark: self.riderDestination!))
            _ = self.generatePolyLine(toDestination:  self.curDestination!)
            
            nextTurnLabel.isHidden = false
            riderInfoButton.isHidden = false
            testButton.isHidden = false
            
            self.currentStatus = status.TO_DEST
            
        }
        self.mapView.removeOverlays(self.mapView.overlays)
    }
    
    func showRoute(_ response: MKDirections.Response) {
        let route = response.routes.first
        mapView.addOverlay(route!.polyline, level: MKOverlayLevel.aboveRoads)
    }
    
    @IBAction func endSession(_ sender: Any) {
        let alert = UIAlertController(title: "End Session", message: "Confirm you want to end your session?", preferredStyle: .alert)
        // add an action (button)
        // need to change handler to a function that also turns off accepting rides in backend
        alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler:{ _ in self.endSession()}))
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func endSession() {
        // end current ride if one exists will be done in backed
        //        self.endRide()
        
        print("----- END SESSION CALLED ------")
        //        getRide().stop()
        self.waiting_for_ride = false
        self.activeRide = false
        nextTurnLabel.isHidden = true
        self.mapView.removeOverlays(self.mapView.overlays)
        testButton.setTitle("Accept Ride", for: .normal)
        //        drop off current rider if they exist
        //        set status to inactive in back end
        self.performSegue(withIdentifier: "returnToEntry", sender: nil)
        
        // post request for leaving an event
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let parameters: [String: Any] = [
            "driver_id": myDriverID
        ]
        let url = URL(string: "https://chariot.augustabt.com/api/leaveEvent")!
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
    }
    
    @IBAction func pauseRidePressed(_ sender: Any) {
        //        dropoff current rider will be done in backend
        self.activeRide = false
        nextTurnLabel.isHidden = true
        testButton.setTitle("Accept Ride", for: .normal)
        self.mapView.removeOverlays(self.mapView.overlays)
        self.waiting_for_ride = false
        
        print("----- PAUSE RIDES CALLED ------")
        
        // post request for pausing an event
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let parameters: [String: Any] = [
            "driver_id": myDriverID
        ]
        let url = URL(string: "https://chariot.augustabt.com/api/pauseDriver")!
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
        
        self.performSegue(withIdentifier: "pauseRides", sender: nil)
    }
    
    func getRide() {
        // post request to getRide
        //send driver_id, current lat, and long
        // set self.ride_id
        print("--- GET RIDE CALLED ----")
        let curCoords = self.currentLocation!.coordinate
        
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let parameters: [String: Any] = [
            "driver_id": myDriverID,
            //TODO: check that this works
            "current_latitude": String(curCoords.latitude),
            "current_longitude": String(curCoords.longitude)
        ]
        let url = URL(string: "https://chariot.augustabt.com/api/getRide")!
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
                print(String(data: data, encoding: .utf8))
                if resp != 200 && self.waiting_for_ride == true {
                    Task {
                        // Delay the task by 1 second:
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        
                        // Perform our operation
                        self.getRide()
                        return
                    }
                    
                } else if resp == 200 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                        print(json)
                        // set riderLocation
                        // set Destination
                        // set rider name
                        self.ride_id = json["ride_id"] as? String ?? "no_id"
                        self.rider_name = json["rider_name"] as? String ?? "no_name"
                        
                        self.riderLocation = self.stringToCLPlacemark(lat: (json["source_latitude"] as? String ?? ""), long: (json["source_longitude"] as? String ?? ""))
                        self.riderDestination = self.stringToCLPlacemark(lat: (json["dest_latitude"] as? String ?? ""), long: (json["dest_longitude"] as? String ?? ""))
                        
                        self.curDestination = MKMapItem(placemark: MKPlacemark(placemark: self.riderLocation!))
                        _ = self.generatePolyLine(toDestination:  self.curDestination!)
                        
                    } catch let error as NSError {
                        print(error)
                    }
                    // set stuff to active
                    self.activeRide = true
                    self.currentStatus = status.TO_PICKUP
                    self.nextTurnLabel.isHidden = false
                    self.riderInfoButton.isHidden = false
                    self.testButton.setTitle("Pickup Rider[s]", for: .normal)
                    self.testButton.isHidden = false
                    self.waiting_for_ride = false
                }
            }
            
            
        }.resume()
        
    }
    
    // call any time pausing or ending session if ride active
    // and on dropoff pressed
    func endRide() {
        
        print("----- END RIDE CALLED ------")
        
        // post request for ending the current ride
        if activeRide == false {
            return
        }
        self.activeRide = false
        self.currentStatus = status.EMPTY
        var resp = 0
        //        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //        let myDriverID : String = appDelegate.driverID
        let parameters: [String: Any] = [
            //            "driver_id": myDriverID,
            "ride_id": self.ride_id
        ]
        let url = URL(string: "https://chariot.augustabt.com/api/endRide")!
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
            if error == nil, let response = response as? HTTPURLResponse {
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                print(resp)
            }
        }.resume()
    }
    
    func stringToCLPlacemark(lat: String, long: String) -> CLPlacemark {
        let coords = CLLocationCoordinate2D(latitude: (lat as NSString).doubleValue, longitude: (long as NSString).doubleValue)
        let mkPlace = MKPlacemark(coordinate: coords)
        let place = CLPlacemark(placemark: mkPlace)
        
        return place
    }
    
    func sendStatus(eta: Double) {
        
        print("----- SEND STATUS CALLED -----")
        
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let curCoords = self.currentLocation!.coordinate
        
        let parameters: [String: Any] = [
            "driver_id": myDriverID,
            "ride_id": self.ride_id,
            "eta": eta,
            "latitude": String(curCoords.latitude),
            "longitude": String(curCoords.longitude)
        ]
        let url = URL(string: "https://chariot.augustabt.com/api/updateDriverStatus")!
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
            if error == nil, let response = response as? HTTPURLResponse {
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                print(resp)
            }
        }.resume()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? RiderDetailsViewController {
            //            pass rider name and eventually image here
            vc.riderName = self.rider_name
        }
    }
    
}
