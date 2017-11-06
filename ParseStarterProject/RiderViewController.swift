//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Vanessa Chu on 2017-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var map: MKMapView!
    var locationManager = CLLocationManager()
    @IBOutlet var callAnUber: UIButton!
    var riderRequestActive = false
    var driverOnWay = false
    
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    func createAlert(title: String, message: String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler:{(action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func callAnUber(_ sender: Any) {
        if riderRequestActive{
            self.callAnUber.setTitle("Call an Uber", for: [])
            riderRequestActive = false
            
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            
            query.findObjectsInBackground(block: {(objects, error) in
            
                if let riderRequests = objects{
                    for riderRequest in riderRequests{
                        riderRequest.deleteInBackground()
                    }
                }
            
            })
        }else{
            self.callAnUber.setTitle("Cancel Uber", for: [])
            riderRequestActive = true
            if userLocation.latitude != 0 && userLocation.longitude != 0 {
                let riderRequest = PFObject(className: "RiderRequest")
                riderRequest["username"] = PFUser.current()?.username
                
                riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
                
                riderRequest.saveInBackground(block: {(success, error) in
                    if success{
                        print("Called an Uber")
                    }else{
                        self.createAlert(title: "Could not call Uber", message: "Please try again")
                        self.riderRequestActive = false
                        self.callAnUber.setTitle("Call an Uber", for: [])
                    }
                    
                })
            }else{
                self.createAlert(title: "Cannot detect location", message: "Please try again")
            }

        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logoutSegue"{
            locationManager.stopUpdatingLocation()
            PFUser.logOut()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let acl = PFACL()
        acl.getPublicWriteAccess = true
        acl.getPublicReadAccess = true

        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: PFUser.current()?.username)
        self.callAnUber.isHidden = true
        
        query.findObjectsInBackground(block: {(objects, error) in
            if let riderRequests = objects{
                if riderRequests.count > 0{
                    self.riderRequestActive = true
                    self.callAnUber.setTitle("Cancel Uber", for: [])
                }
                self.callAnUber.isHidden = false
            }
            
        })
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location?.coordinate{
    
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            if driverOnWay == false{
                let region: MKCoordinateRegion = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                self.map.setRegion(region, animated:true )
                self.map.removeAnnotations(self.map.annotations)
                
                let annotation = MKPointAnnotation()
                
                annotation.title = "Your location"
                annotation.coordinate = userLocation
                
                self.map.addAnnotation(annotation)
            }
        
            
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            
            query.findObjectsInBackground(block: {(objects, error) in
                
                if let riderRequests = objects{
                    for riderRequest in riderRequests{
                        riderRequest["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                        riderRequest.saveInBackground()
                    }
                }
                
            })
        }
        
        if riderRequestActive{
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: PFUser.current()?.username)
            
            query.findObjectsInBackground(block: {(objects, error) in
             
                if let riderRequests = objects{
                    for riderRequest in riderRequests{
                        if let driverUsername = riderRequest["driverResponded"]{
                            let driverQuery = PFQuery(className: "DriverLocation")
                            driverQuery.whereKey("username", equalTo: driverUsername)
                            driverQuery.findObjectsInBackground(block: {(objects, error) in
                                if let driverLocations = objects{
                                    for driverLocationObject in driverLocations{
                                        if let driverLocation = driverLocationObject["location"] as? PFGeoPoint{
                                            self.driverOnWay = true
                                            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            let riderCLLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                            
                                            let distance = riderCLLocation.distance(from: driverCLLocation) / 1000
                                            let roundedDistance = round(distance * 100) / 100
                                            
                                            self.callAnUber.setTitle("Driver is \(roundedDistance) km away!", for: [])
                                            
                                            let latDelta = abs(driverLocation.latitude - self.userLocation.latitude) * 2 + 0.005
                                            let lonDelta = abs(driverLocation.longitude - self.userLocation.longitude) * 2 + 0.005
                                            
                                            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                            
                                            self.map.removeAnnotations(self.map.annotations)
                                            
                                            
                                            self.map.setRegion(region, animated: true)
                                            
                                            let userAnnotation = MKPointAnnotation()
                                            userAnnotation.coordinate = CLLocationCoordinate2D(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                            userAnnotation.title = "Your location"
                                            self.map.addAnnotation(userAnnotation)
                                            
                                            let driverAnnotation = MKPointAnnotation()
                                            driverAnnotation.coordinate = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            driverAnnotation.title = "Driver"
                                            
                                            self.map.addAnnotation(driverAnnotation)
                                            
                                        }
                                        
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
