//
//  AppDelegate.swift
//  chariot
//
//  Created by Reese Crowell on 9/19/22.
//

import UIKit
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var driverID = ""
    var eventID = ""
    var eventName = ""
    var eventAddress = ""
    var eventRadius =  0.0
    var eventLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        
        //TODO: pause instead of end and save / set driver status
        print("----- END SESSION CALLED FROM APP DELEGATE ------")
        var resp = 0
        let semaphore = DispatchSemaphore(value: 0)
        let parameters: [String: Any] = [
            "driver_id": driverID
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
                semaphore.signal()
            }
        }.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
}

