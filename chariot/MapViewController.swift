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
    
    @IBOutlet weak var etaLabel: UILabel!
    
    @IBOutlet weak var distanceToTurnLabel: UILabel!
    @IBOutlet weak var directionsTurnImage: UIImageView!
    @IBOutlet weak var distanceToDestLabel: UILabel!
    @IBOutlet weak var turnByTurnView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var endSessionButton: UIBarButtonItem!
    @IBOutlet weak var pauseSessionButton: UIBarButtonItem!
    
    @IBOutlet weak var sidePanelView: UIView!
    private var zoomDiff: Double = 0.0
    
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    
    private var riderLocation: CLPlacemark?
    private var riderLocationPin: MKPointAnnotation = MKPointAnnotation()
    
    
    private var riderDestination: CLPlacemark?
    private var riderDestinationPin: MKPointAnnotation = MKPointAnnotation()
    
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
    @IBOutlet weak var userLocationBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        mapView.delegate = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        nextTurnLabel.layer.cornerRadius = 8
        nextTurnLabel.clipsToBounds = true
        
        testButton.layer.cornerRadius = testButton.frame.width / 2
        testButton.clipsToBounds = true
        //        testButton.isHidden = true
        
        riderInfoButton.layer.cornerRadius = riderInfoButton.frame.width/2
        riderInfoButton.clipsToBounds = true
        
        sidePanelView.isHidden = true
        
        turnByTurnView.layer.cornerRadius = 10
        turnByTurnView.isHidden = true
        
        bottomView.isHidden = true
        
        // To provide the shadow
        turnByTurnView.layer.shadowRadius = 10
        turnByTurnView.layer.shadowOpacity = 1.0
        turnByTurnView.layer.shadowOffset = CGSize(width: 5, height: 5)
        turnByTurnView.layer.shadowColor = UIColor.black.cgColor
        
        
        // Check for Location Services
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        
        getEventDetails()
        //        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        //           toolbarItems = [trackingButton]
        
    }
    @IBAction func userLocationToggle(_ sender: Any) {
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
    override func viewDidAppear(_ animated: Bool) {
        //        print("accepting Rides")
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
        //        print(jsonString!)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let _ = data, let response = response as? HTTPURLResponse {
                //                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                //                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                //                print(resp)
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
            //            let viewRegion = MKCoordinateRegion(center: locations.last!.coordinate, latitudinalMeters: 400 + zoomDiff, longitudinalMeters: 400 + zoomDiff)
            //            mapView.setRegion(viewRegion, animated: true)
            
            //            mapView.userTrackingMode = .followWithHeading
            
            //            print("would be this often")
            // probably have to add this part to dropoff button
            // updates too slow to keep up with highway driving
            //            mapView.removeOverlays(self.mapView.overlays)
            
            if activeRide {
                if self.currentStatus == status.TO_PICKUP {
                    let eta = self.generatePolyLine(toDestination: self.curDestination!)
                    sendStatus(eta: eta, hasRider: false, inRide: true)
                } else {
                    let eta = self.generatePolyLine(toDestination: self.curDestination!)
                    sendStatus(eta: eta, hasRider: true, inRide: true)
                }
            } else {
                sendStatus(eta: 0, hasRider: false, inRide: false)
            }
        }
        
        if currentLocation == nil {
            // Zoom to user location
            if  let userLocation = locations.last {
                let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 400 + zoomDiff, longitudinalMeters: 400 + zoomDiff)
                mapView.setRegion(viewRegion, animated: false)
            }
        }
    }
    
    //    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    //        mapView.camera.heading = newHeading.magneticHeading
    //        mapView.setCamera(mapView.camera, animated: true)
    //
    //    }
    //    func centerViewOnUserLocation() { mapView.setUserTrackingMode(.followWithHeading, animated:true)}
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 8.0
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
            
            //            print("show steps? :")
            //            print(self.route!.steps[1].instructions)
            //            print(String(self.route!.steps[1].distance))
            
            var totalDist = 0.0
            for step in self.route!.steps {
                totalDist += step.distance
            }
            // set eta label
            self.etaLabel.text = self.timeConversion(seconds: self.route!.expectedTravelTime)
            // set total distance
            self.distanceToDestLabel.text = self.distanceConversion(meters: totalDist)
            
            self.nextTurnLabel.text = self.route!.steps[1].instructions
            self.distanceToTurnLabel.text = self.distanceConversion(meters: self.route!.steps[1].distance)
            if (self.route!.steps[1].instructions.contains("left")) { // left
                self.directionsTurnImage.image = UIImage(systemName: "arrow.turn.up.left") //arrowshape.turn.up.left
            } else if (self.route!.steps[1].instructions.contains("right")) { // left
                self.directionsTurnImage.image = UIImage(systemName: "arrow.turn.up.right") //arrowshape.turn.up.left
            } else if (self.route!.steps[1].instructions.contains("destination")) {
                self.directionsTurnImage.image = UIImage(systemName: "mappin.circle") // mappin.circle
            } else {
                self.directionsTurnImage.image = UIImage(systemName: "arrow.up")
            }
        }
        if self.route != nil {
            return self.route!.expectedTravelTime
        }
        return -1
    }
    
    // converts seconds into more readable value
    func timeConversion (seconds: Double) -> String {
        if seconds < 60 {
            return "< 1 min"
        } else {
            let mins = seconds / 60
            if (seconds.remainder(dividingBy: 60) != 0) {
                return String(format: "%.0f mins", (mins + 1))
            } else {
                return String(format: "%.0f mins", mins)
            }
        }
        
        
    }
    
    func distanceConversion (meters: Double) -> String {
        if meters > 153 {
            let miles = meters / 1609
            return String(format: "%.1f miles", miles)
        } else {
            let feet = round(meters * 3.281 / 50) * 50 // should give value of every 50 feet
            return String(format: "%.0f feet", feet)
        }
        
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
            turnByTurnView.isHidden = true
            bottomView.isHidden = true
            sidePanelView.isHidden = true
            //            make a new get ride request
            self.currentStatus = status.EMPTY
            self.waiting_for_ride = true
            self.mapView.removeAnnotation(self.riderDestinationPin)
            
            // TODO: make a popup to ask if you want to get ride if no go to pause screen
            let alert = UIAlertController(title: "Continue Driving?", message: "Confirm you are ready for your next ride or pause the session.", preferredStyle: .alert)
            // add an action (button)
            // need to change handler to a function that also turns off accepting rides in backend
            alert.addAction(UIAlertAction(title: "Pause Rides", style: UIAlertAction.Style.default, handler:{ _ in self.pauseRidePressed(self)}))
            alert.addAction(UIAlertAction(title: "Keep Driving", style: UIAlertAction.Style.default, handler: {_ in self.getRide()}))
            alert.addAction(UIAlertAction(title: "End Session", style: UIAlertAction.Style.default, handler: {_ in self.endSession()}))
            // show the alert
            self.present(alert, animated: true, completion: nil)
            
        } // this is on the way to rider, would press button now once you get to the rider
        else if self.currentStatus == status.TO_PICKUP {
            testButton.setTitle("Dropoff", for: .normal)
            self.mapView.removeAnnotation(self.riderLocationPin)
            self.mapView.addAnnotation(self.riderDestinationPin)
            // need to put address given here instead of default address
            
            self.curDestination = MKMapItem(placemark: MKPlacemark(placemark: self.riderDestination!))
            _ = self.generatePolyLine(toDestination:  self.curDestination!)
            
            turnByTurnView.isHidden = false
            bottomView.isHidden = false
            sidePanelView.isHidden = false
            
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
        
        //        print("----- END SESSION CALLED ------")
        //        getRide().stop()
        self.waiting_for_ride = false
        self.activeRide = false
        turnByTurnView.isHidden = true
        bottomView.isHidden = true
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
        //        print(jsonString!)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let _ = data, let response = response as? HTTPURLResponse {
                //                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                //                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                //                print(resp)
            }
        }.resume()
    }
    
    @IBAction func pauseRidePressed(_ sender: Any) {
        //        dropoff current rider will be done in backend
        self.activeRide = false
        bottomView.isHidden = true
        turnByTurnView.isHidden = true
        sidePanelView.isHidden = true
        
        //        nextTurnLabel.isHidden = true
        //        testButton.setTitle("Accept Ride", for: .normal)
        self.mapView.removeOverlays(self.mapView.overlays)
        self.waiting_for_ride = false
        
        //        print("----- PAUSE RIDES CALLED ------")
        
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
        //        print(jsonString!)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let _ = data, let response = response as? HTTPURLResponse {
                //                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                //                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                //                print(resp)
            }
        }.resume()
        
        self.performSegue(withIdentifier: "pauseRides", sender: nil)
    }
    
    func getRide() {
        // post request to getRide
        //send driver_id, current lat, and long
        // set self.ride_id
        
        //        print("--- GET RIDE CALLED ----")
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
        //        print(jsonString!)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                //                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                //                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                //                print(resp)
                //                print(String(data: data, encoding: .utf8))
                if resp != 200 && self.waiting_for_ride == true {
                    Task {
                        // Delay the task by 5 second:
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        
                        // Perform our operation
                        self.getRide()
                        return
                    }
                    
                } else if resp == 200 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                        //                        print(json)
                        // set riderLocation
                        // set Destination
                        // set rider name
                        self.ride_id = json["ride_id"] as? String ?? "no_id"
                        self.rider_name = json["rider_name"] as? String ?? "no_name"
                        
                        self.riderLocation = self.stringToCLPlacemark(lat: (json["source_latitude"] as? String ?? ""), long: (json["source_longitude"] as? String ?? ""))
                        self.riderLocationPin.coordinate = CLLocationCoordinate2D(latitude: Double(json["source_latitude"] as? String ?? "0.0")!, longitude: Double(json["source_longitude"] as? String ?? "0.0")!)
                        
                        self.riderDestination = self.stringToCLPlacemark(lat: (json["dest_latitude"] as? String ?? ""), long: (json["dest_longitude"] as? String ?? ""))
                        self.riderDestinationPin.coordinate = CLLocationCoordinate2D(latitude: Double(json["dest_latitude"] as? String ?? "0.0")!, longitude: Double(json["dest_longitude"] as? String ?? "0.0")!)
                        
                        self.curDestination = MKMapItem(placemark: MKPlacemark(placemark: self.riderLocation!))
                        _ = self.generatePolyLine(toDestination:  self.curDestination!)
                        
                    } catch let error as NSError {
                        //                        print(error)
                    }
                    // set stuff to active
                    DispatchQueue.main.async {
                        self.mapView.addAnnotation(self.riderLocationPin)
                        self.activeRide = true
                        self.currentStatus = status.TO_PICKUP
                        while self.turnByTurnView.isHidden == true {
                            self.turnByTurnView.isHidden = false
                            self.turnByTurnView.layoutIfNeeded()
                        }
                        while self.bottomView.isHidden == true {
                            self.bottomView.isHidden = false
                            self.bottomView.layoutIfNeeded()
                        }
                        while self.sidePanelView.isHidden == true {
                            self.sidePanelView.isHidden = false
                            self.sidePanelView.layoutIfNeeded()
                        }
                        self.testButton.setTitle("Pickup Rider[s]", for: .normal)
                        self.waiting_for_ride = false
                        self.view.layoutIfNeeded()
                    }
                }
            }
        }.resume()
        /*
         // for testing
         self.ride_id =  "no_id"
         self.rider_name = "no_name"
         
         self.riderLocation = self.stringToCLPlacemark(lat: "40.4296268", long: "-86.9171915")
         self.riderDestination = self.stringToCLPlacemark(lat: "40.4237144", long: "-86.9125957")
         
         self.curDestination = MKMapItem(placemark: MKPlacemark(placemark: self.riderLocation!))
         _ = self.generatePolyLine(toDestination:  self.curDestination!)
         // set stuff to active
         self.activeRide = true
         self.currentStatus = status.TO_PICKUP
         self.turnByTurnView.isHidden = false
         self.bottomView.isHidden = false
         self.sidePanelView.isHidden = false
         self.testButton.setTitle("Pickup Rider[s]", for: .normal)
         self.testButton.isHidden = false
         self.waiting_for_ride = false
         */
    }
    
    // call any time pausing or ending session if ride active
    // and on dropoff pressed
    func endRide() {
        
        //        print("----- END RIDE CALLED ------")
        
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
        //        print(jsonString!)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let response = response as? HTTPURLResponse {
                //                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                //                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                //                print(resp)
            }
        }.resume()
    }
    
    func stringToCLPlacemark(lat: String, long: String) -> CLPlacemark {
        let coords = CLLocationCoordinate2D(latitude: (lat as NSString).doubleValue, longitude: (long as NSString).doubleValue)
        let mkPlace = MKPlacemark(coordinate: coords)
        let place = CLPlacemark(placemark: mkPlace)
        
        return place
    }
    
    func sendStatus(eta: Double, hasRider: Bool, inRide: Bool) {
        
        //        print("----- SEND STATUS CALLED -----")
        
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        let curCoords = self.currentLocation!.coordinate
        var parameters: [String: Any] = [:]
        
        if !inRide {
            parameters = [
                "driver_id": myDriverID,
                "latitude": String(curCoords.latitude),
                "longitude": String(curCoords.longitude)
            ]
        } else {
            parameters = [
                "driver_id": myDriverID,
                "ride_id": self.ride_id,
                "eta": eta,
                "has_rider": hasRider,
                "latitude": String(curCoords.latitude),
                "longitude": String(curCoords.longitude)
            ]
        }
        
        let url = URL(string: "https://chariot.augustabt.com/api/updateDriverStatus")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return
        }
        let jsonString = String(data: httpBody, encoding: .utf8)
        //        print(jsonString!)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let response = response as? HTTPURLResponse {
                //                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                //                print("statusCode: \(response.statusCode)")
                resp = response.statusCode
                //                print(resp)
            }
        }.resume()
    }
    
    func getEventDetails() {
        var resp = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let myDriverID : String = appDelegate.driverID
        //            let curCoords = self.currentLocation!.coordinate
        let parameters = [
            "driver_id": myDriverID,
        ]
        // fix url
        let url = URL(string: "https://chariot.augustabt.com/api/getDriverEventInfo")!
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
                if resp == 400 {
                    self.getEventDetails()
                } else {
                    
                    do {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                        print(json)
                        appDelegate.eventAddress = json["address"] as! String
                        appDelegate.eventName = json["eventName"] as! String
                        appDelegate.eventRadius = (json["maxRadius"] as! Double) * 1600
                        let geocoder = CLGeocoder()
                        geocoder.geocodeAddressString(appDelegate.eventAddress, completionHandler: {(placemarks, error) -> Void in
                            if((error) != nil){
                                print("Error", error ?? "")
                            }
                            if let placemark = placemarks?.first {
                                appDelegate.eventLocation = placemark.location!.coordinate
                            }
                        })
                        
                        
                    } catch let error as NSError {
                        print(error)
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "toRiderDetails", let vc = segue.destination as? RiderDetailsViewController {
            //            pass rider name and eventually image here
            vc.riderName = self.rider_name
        }
        if segue.identifier == "toRiderQueue", let vc = segue.destination as? EventDetialsViewController {
            //            var resp = 0
            //            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            //            let myDriverID : String = appDelegate.driverID
            ////            let curCoords = self.currentLocation!.coordinate
            //            let parameters = [
            //                    "driver_id": myDriverID,
            //                ]
            //            // fix url
            //            let url = URL(string: "https://chariot.augustabt.com/api/getDriverEventInfo")!
            //            var request = URLRequest(url: url)
            //            request.httpMethod = "POST"
            //            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            //            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            //                return
            //            }
            //            let jsonString = String(data: httpBody, encoding: .utf8)
            //            print(jsonString!)
            //            request.httpBody = httpBody
            //            request.timeoutInterval = 20
            //
            //            let session = URLSession.shared
            //            session.dataTask(with: request) { (data, response, error) in
            //                if error == nil, let data = data, let response = response as? HTTPURLResponse {
            //                    print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
            //                    print("statusCode: \(response.statusCode)")
            //                    resp = response.statusCode
            //                    print(resp)
            //
            //                    do {
            //                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            //                        print(json)
            //                        vc.address = json["address"] as! String
            //                        vc.eventNameLabel.text = json["eventName"] as? String
            //                        vc.addressLabel.text = json["address"] as? String
            //                        vc.radius = json["maxRadius"] as! Double
            ////                        vc.viewDidLoad()
            //
            //                    } catch let error as NSError {
            //                        print(error)
            //                    }
            //                }
            //            }.resume()
            
        }
    }
    
}
