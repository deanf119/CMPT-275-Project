//
//  CaretakerMapViewController.swift
//  Remembral
//
//  Team: Group 2
//  Created by Dean Fernandes on 2018-11-12.
//  Edited: Dean Fernandes, Alwin Leong
//
//  Caretaker Map page
//  Will be used in Version 2
//  Known bugs:
//
//

import UIKit
import MapKit
import CoreLocation
import GoogleMaps
import FirebaseCore
import FirebaseDatabase
import UserNotifications

class CaretakerMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    var locationManager = CLLocationManager()
    
    var marker = GMSMarker()
    let mapView = GMSMapView(frame: .zero)
    var displayedFence: [XYPoint]?
    var warningIcon: UIImageView?
    
    func initializeWarning() {
        let imageName = "warning_sign"
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        warningIcon = UIImageView(image: image!)
        warningIcon?.tintColor = .red
        let navHeight = self.navigationController!.navigationBar.frame.size.height
        let window = UIApplication.shared.keyWindow
        let topPadding = (window?.safeAreaInsets.top)! + navHeight
        warningIcon?.frame = CGRect(x: 5, y: topPadding, width: 50, height: 50)

        self.mapView.addSubview(warningIcon!)
        self.mapView.bringSubviewToFront(warningIcon!)
        warningIcon?.isHidden = true

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if CLLocationManager.locationServicesEnabled() {
            print("Location services are enabled")
            if CLLocationManager.authorizationStatus() == .restricted ||
                CLLocationManager.authorizationStatus() == .denied ||
                CLLocationManager.authorizationStatus() == .notDetermined{
                
                locationManager.requestWhenInUseAuthorization();
            }
            
            locationManager.desiredAccuracy = 1.0
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        } else {
            print("Please enabled location services")
        }
        
        
        mapView.isMyLocationEnabled = true
        
        /*mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        */
        self.view = mapView
        
        // Patient's Current Location Marker: Need to update Real time
        marker.position = CLLocationCoordinate2DMake(0, 0)
        
        //Select a suitable image
        marker.icon = UIImage(named: "map person")
        
        marker.map = mapView
        
        //Needs to be done using user id queries
        //
        let userID = "iKbAZiqWylPvVNkOLPlYfzyuzan2" //Auth.auth().currentUser?.uid
        FirebaseDatabase.sharedInstance.usersRef.child(userID).observe(.value) { (snapshot: DataSnapshot) in
            let userInfo = snapshot.value as! [String:Any]
            self.marker.title = userInfo["name"] as? String ?? "undefined"
        }

        
        //Updates marker whenever there's a location update.
        LocationServicesHandler.newestLocationUpdates(forID: userID) { (locationReturned) in
            self.marker.position.latitude = locationReturned.latitude
            self.marker.position.longitude = locationReturned.longitude
            self.marker.snippet = "Last Updated @ " + String(locationReturned.time)
            if self.mapView.selectedMarker != nil {
                let cameraUpdate = GMSCameraUpdate.setTarget((self.mapView.selectedMarker?.position)!)
                self.mapView.moveCamera(cameraUpdate)
            }
            if self.displayedFence != nil {
//THIS LINE OF CODE TO DETECTS IF A COORDINATE IS INSIDE THE FENCE
                 let result = LocationServicesHandler.isPointInsideFence(currentLocation: locationReturned.asCoordinate(), fence: self.displayedFence!)
                self.setAutomaticSOSNotification(shouldSetRemove: result)
                self.warningIcon?.isHidden = result

            }
        }

        //Set a time range for the generation of the fence?
        //let day_in_seconds = 60.0 * 60.0 * 24.0 / 2
        let first = 0.0 //LocationServicesHandler.getNewEndingPoint() - 2.5 * day_in_seconds
        LocationServicesHandler.readLocations(forID: userID, startingPoint: first){
            (locationList) in
            self.displayedFence = LocationServicesHandler.generateFence(forUser: userID, forLocations: locationList, mapView: self.mapView)
            
        }
        
        initializeWarning()
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userCoord = (locationManager.location?.coordinate)!
        if self.mapView.selectedMarker == nil{
            let cameraMove = GMSCameraUpdate.setTarget(userCoord, zoom: 12)
            mapView.moveCamera(cameraMove)
        }

    }
    
    func setAutomaticSOSNotification(shouldSetRemove: Bool){
        if !shouldSetRemove{
            let category = UNNotificationCategory(identifier: "LocationSOS", actions: [], intentIdentifiers: [], options: [])
            UNUserNotificationCenter.current().setNotificationCategories([category])
            let content = UNMutableNotificationContent()
            content.title = "ALERT!"
            content.categoryIdentifier = "LocationSOS"
            content.body = "Patient has been out of Safe Areas for 15 minutes."
            content.sound = UNNotificationSound.default
            
            let date = Date().addingTimeInterval(15.0 * 60.0)
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "LocationSOS", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["LocationSOS"])
        }
    }
   // func locationManager(_ manager: CLLocationManager, DidResumeLocationUpdates ) {
   //     return 0
   // }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Unable to access location")
    }
    
}
