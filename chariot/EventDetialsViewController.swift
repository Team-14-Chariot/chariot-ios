//
//  EventDetialsViewController.swift
//  chariot
//
//  Created by Reese Crowell on 11/28/22.
//

import UIKit
import MapKit

class EventDetialsViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var eventNameLabel: UILabel!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var eventLocationPin: MKPointAnnotation = MKPointAnnotation()
    
    
    var radius: Double = 250
    var name: String = "event name"
    var address: String = "607 N University St, West Lafayette, IN 47906"
    var eventLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0) //{
        //        didSet {
        //            self.eventLocationPin.coordinate = self.eventLocation
        //            let viewRegion = MKCoordinateRegion(center: self.eventLocation, latitudinalMeters: (self.radius * 1.25 * 1600), longitudinalMeters: (self.radius * 1.25 * 1600))
        //            self.mapView.addOverlay(MKCircle(center: self.eventLocation, radius: self.radius * 1600))
        //            self.mapView.setRegion(viewRegion, animated: false)
        //            self.mapView.addAnnotation(self.eventLocationPin)
        //        }
    //}
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.eventNameLabel.text = appDelegate.eventName
        self.addressLabel.text = appDelegate.eventAddress
        self.radius = appDelegate.eventRadius
        self.eventLocation = appDelegate.eventLocation
        
//        let geocoder = CLGeocoder()
//        geocoder.geocodeAddressString(self.address, completionHandler: {(placemarks, error) -> Void in
//            if((error) != nil){
//                print("Error", error ?? "")
//            }
//            if let placemark = placemarks?.first {
//                self.eventLocation = placemark.location!.coordinate
//                self.eventLocationPin.coordinate = self.eventLocation
//                let viewRegion = MKCoordinateRegion(center: self.eventLocation, latitudinalMeters: (self.radius * 1.25), longitudinalMeters: (self.radius * 1.25 ))
//                self.mapView.addOverlay(MKCircle(center: self.eventLocation, radius: self.radius))
//
//                self.mapView.setRegion(viewRegion, animated: false)
//                self.mapView.addAnnotation(self.eventLocationPin)
//            }
//        })
        self.eventLocationPin.coordinate = self.eventLocation
        let viewRegion = MKCoordinateRegion(center: self.eventLocation, latitudinalMeters: (self.radius * 1.25), longitudinalMeters: (self.radius * 1.25 ))
        self.mapView.addOverlay(MKCircle(center: self.eventLocation, radius: self.radius))
        
        self.mapView.setRegion(viewRegion, animated: false)
        self.mapView.addAnnotation(self.eventLocationPin)
        
        mapView.delegate = self
        //        self.addressLabel.text = self.address
        
        // Do any additional setup after loading the view.
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
//            print("\n\n\n\\n\n *******\t it's a circle \t*******\n\n\n")
            let renderer = MKCircleRenderer(circle: circle)
            renderer.lineWidth = 5.0
            renderer.alpha = 0.25
            renderer.fillColor = UIColor.blue
            renderer.strokeColor = UIColor.blue
            
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
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
