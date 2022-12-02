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
    var name: String = "event name" {
        didSet {
            print("VALUE WAS CHANGED")
            self.eventNameLabel.text = name
        }
    }
    var address: String = "607 N University St, West Lafayette, IN 47906" {
        didSet {
            self.addressLabel.text = address
        }
    }
    var eventLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0) {
        didSet {
            self.eventLocationPin.coordinate = self.eventLocation
            let viewRegion = MKCoordinateRegion(center: self.eventLocation, latitudinalMeters: self.radius * 1.25, longitudinalMeters: self.radius * 1.25)
            self.mapView.addOverlay(MKCircle(center: self.eventLocation, radius: self.radius))
            
            self.mapView.setRegion(viewRegion, animated: false)
            self.mapView.addAnnotation(self.eventLocationPin)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                    print(json)
                    self.address = json["address"] as! String
                    self.eventNameLabel.text = json["eventName"] as? String
                    
                    self.name = json["eventName"] as! String

                    self.addressLabel.text = json["address"] as? String
                    self.radius = json["maxRadius"] as! Double
//                        vc.viewDidLoad()
                    
                    let geocoder = CLGeocoder()
                    geocoder.geocodeAddressString(self.address, completionHandler: {(placemarks, error) -> Void in
                        if((error) != nil){
                            print("Error", error ?? "")
                        }
                        if let placemark = placemarks?.first {
                            self.eventLocation = placemark.location!.coordinate
                            self.addressLabel.text = self.address
                            self.eventNameLabel.text = self.name
                            
                        }
                    })

                } catch let error as NSError {
                    print(error)
                }
            }
        }.resume()
        
//        let geocoder = CLGeocoder()
//        geocoder.geocodeAddressString(self.address, completionHandler: {(placemarks, error) -> Void in
//            if((error) != nil){
//                print("Error", error ?? "")
//            }
//            if let placemark = placemarks?.first {
//                self.eventLocation = placemark.location!.coordinate
//                self.addressLabel.text = self.address
//                self.eventNameLabel.text = self.name
//
//            }
//        })
        
//        self.eventLocationPin.coordinate = self.eventLocation
//        let viewRegion = MKCoordinateRegion(center: self.eventLocation, latitudinalMeters: self.radius * 1.25, longitudinalMeters: self.radius * 1.25)
//        self.mapView.addOverlay(MKCircle(center: self.eventLocation, radius: self.radius))
//
//        self.mapView.setRegion(viewRegion, animated: false)
//        self.mapView.addAnnotation(self.eventLocationPin)
        
        mapView.delegate = self
//        self.addressLabel.text = self.address
        
        // Do any additional setup after loading the view.
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            print("\n\n\n\\n\n *******\t it's a circle \t*******\n\n\n")
            let renderer = MKCircleRenderer(circle: circle)
            renderer.lineWidth = 5.0
            renderer.alpha = 0.1
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
