//
//  EventDetialsViewController.swift
//  chariot
//
//  Created by Reese Crowell on 11/28/22.
//

import UIKit
import MapKit

class EventDetialsViewController: UIViewController {

    @IBOutlet weak var eventNameLabel: UILabel!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var eventBoundaryMap: MKMapView!
    var eventLocationPin: MKPointAnnotation = MKPointAnnotation()
    
    
    var lat: CLLocationDegrees = 40.42383268068071
    var long: CLLocationDegrees = -86.91261817785627
    var radius: Double = 500

    override func viewDidLoad() {
        super.viewDidLoad()
        let eventLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        eventLocationPin.coordinate = eventLocation
        let viewRegion = MKCoordinateRegion(center: eventLocation, latitudinalMeters: radius * 1.25, longitudinalMeters: radius * 1.25)
        let region = CLCircularRegion(center: eventLocation, radius: 5000, identifier: "geofence")
        eventBoundaryMap.addOverlay(MKCircle(center: eventLocation, radius: 200))
        eventBoundaryMap.setRegion(viewRegion, animated: false)
        self.eventBoundaryMap.addAnnotation(eventLocationPin)
        
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
