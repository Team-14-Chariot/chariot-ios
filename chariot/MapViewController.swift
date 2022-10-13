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
    private var destination: CLPlacemark?
    
    private var route: MKRoute?
    
    
    private var activeRide: Bool = false
    private var curDestination: MKMapItem?
    
    var driverID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Driver ID:")
        print(driverID)

        mapView.delegate = self

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        nextTurnLabel.layer.cornerRadius = 8
        nextTurnLabel.clipsToBounds = true
        nextTurnLabel.isHidden = true
        
        testButton.layer.cornerRadius = testButton.frame.width / 2
        testButton.clipsToBounds = true
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
    }

    // MARK - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last
            let viewRegion = MKCoordinateRegion(center: locations.last!.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(viewRegion, animated: true)
            
            // probably have to add this part to dropoff button
            // updates too slow to keep up with highway driving
//            mapView.removeOverlays(self.mapView.overlays)
            
            if activeRide {
                self.generatePolyLine(toDestination: self.curDestination!)
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
        let geocoder = CLGeocoder()
        if self.activeRide {
            self.activeRide = false;
            testButton.setTitle("Accept Ride", for: .normal)
            while !mapView.overlays.isEmpty {
                mapView.removeOverlays(self.mapView.overlays)
                print("removed an overlay")
            }
            nextTurnLabel.isHidden = true
            riderInfoButton.isHidden = true

        } else {
            self.activeRide = true
            testButton.setTitle("Dropoff", for: .normal)
            // need to put address given here instead of default address
            geocoder.geocodeAddressString("851 David Ross Rd, West Lafayette, IN 47906") {
                placemarks, error in
//                let dest = placemarks?.first
                self.curDestination = MKMapItem(placemark: MKPlacemark(placemark: (placemarks?.first)!))
                let eta = self.generatePolyLine(toDestination:  self.curDestination!)
                print(eta)
            }
            nextTurnLabel.isHidden = false
            riderInfoButton.isHidden = false

        }
        
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
        self.activeRide = false
        nextTurnLabel.isHidden = true
        self.mapView.removeOverlays(self.mapView.overlays)
        testButton.setTitle("Accept Ride", for: .normal)
//        drop off current rider if they exist
//        set status to inactive in back end
        self.performSegue(withIdentifier: "returnToEntry", sender: nil)
    }
    @IBAction func pauseRidePressed(_ sender: Any) {
//        dropoff current rider
        self.activeRide = false
        nextTurnLabel.isHidden = true
        testButton.setTitle("Accept Ride", for: .normal)
        self.mapView.removeOverlays(self.mapView.overlays)
//        set status to offline in backend
        self.performSegue(withIdentifier: "pauseRides", sender: nil)
    }
    
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? RiderDetailsViewController {
//            pass rider name and eventually image here
            vc.riderName = "Passed Rider Name"
            print("should be passing the name here")
        }
    }
    
    
    

}
