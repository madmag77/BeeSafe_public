//
//  MapViewController.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 18/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import UIKit
import GoogleMaps
import SnapKit

protocol MapViewModel: class {
    func viewDidLoad()
    func tapMapBtn()
    func tapCameraBtn()
}

class MapViewController: UIViewController {
    public var viewModel: MapViewModel?
    
    private var locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var mapView: GMSMapView!
    private let zoomLevel: Float = 17.0
    private let defaultLocation = CLLocation()
    private var heatMapBtn: UIButton = UIButton()
    private var cameraBtn: UIButton = UIButton()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let viewModel = MapViewModelImpl(store: store)
        self.viewModel = viewModel
        viewModel.view = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)

        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 40)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        
        mapView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
        
        addGroundOverlay()
        //room1Poly = addRoom1(UIColor(displayP3Red: 255, green: 0, blue: 0, alpha: 0.5))
        //room1Poly?.map = mapView
        
        initUI()
        viewModel?.viewDidLoad()
    }
    
    private func initUI() {
        view.addSubview(heatMapBtn)
        heatMapBtn.setImage(UIImage(named: "heapMap"), for: .normal)
        heatMapBtn.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(view).offset(-40)
            make.bottom.equalTo(view).offset(-40)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        heatMapBtn.addTarget(self, action: #selector(tapMapBtn(_:)), for: .touchUpInside)
        
        view.addSubview(cameraBtn)
        cameraBtn.setImage(UIImage(named: "cameraIcon"), for: .normal)
        cameraBtn.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(view).offset(40)
            make.bottom.equalTo(view).offset(-40)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        cameraBtn.addTarget(self, action: #selector(tapGoCameraBtn(_:)), for: .touchUpInside)
    }

    @objc
    private func tapMapBtn(_ sender: NSObject) {
        viewModel?.tapMapBtn()
    }
    
    @objc
    private func tapGoCameraBtn(_ sender: NSObject) {
        dismiss(animated: true, completion: nil)
    }

    private func addGroundOverlay() {
        let southWest = CLLocationCoordinate2D(latitude: 1.2878514, longitude: 103.8479035)
        let northEast = CLLocationCoordinate2D(latitude: 1.2880943, longitude: 103.8475332)
        let overlayBounds = GMSCoordinateBounds(coordinate: southWest, coordinate: northEast)
        
        let icon = UIImage(named: "plan")
        
        let overlay = GMSGroundOverlay(bounds: overlayBounds, icon: icon)
        overlay.bearing = 123
        overlay.opacity = 0.8
        overlay.map = mapView
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        mapView.camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        locationManager.stopUpdatingLocation()
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

extension MapViewController: GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, idleAt cameraPosition: GMSCameraPosition) {
        print("chage position \(cameraPosition)")
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        
    }
}

extension MapViewController: MapViewModelDelegate {
    func addGroundOverlay(_ overlay: GMSGroundOverlay) {
         overlay.map = mapView
    }
    
    func addRooms(_ rooms: [GMSPolygon]) {
        rooms.forEach { (room) in
            room.map = mapView
        }
    }
    
    func addMarkers(_ markers: [GMSMarker]) {
        markers.forEach { marker in
            marker.map = mapView
        }
    }

    func clear() {
        mapView.clear()
    }
    
    func switchToMarkers() {
        heatMapBtn.setImage(UIImage(named: "heatMap"), for: .normal)
    }
    
    func switchToHeatmap() {
        heatMapBtn.setImage(UIImage(named: "mapIcon"), for: .normal)
    }
}
