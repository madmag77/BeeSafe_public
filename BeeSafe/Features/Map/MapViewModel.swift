//
//  MapViewModel.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 19/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import Foundation
import GoogleMaps
import ReSwift

protocol MapViewModelDelegate: class {
    func addGroundOverlay(_ overlay: GMSGroundOverlay)
    func addRooms(_ rooms: [GMSPolygon])
    func addMarkers(_ markers: [GMSMarker])
    func clear()
    func switchToMarkers()
    func switchToHeatmap()
}

class Room {
    let polygon: GMSPolygon
    var degreeDanger: DangerDegree
    
    init(polygon: GMSPolygon, degreeDanger: DangerDegree) {
        self.polygon = polygon
        self.degreeDanger = degreeDanger
    }
    
    func increaseDanger() {
        guard degreeDanger != .heavy else { return }
        
        degreeDanger = DangerDegree(rawValue: degreeDanger.rawValue + 1)!
    }
}

class MapViewModelImpl: MapViewModel {
    private var store: Store<BeeSafeState>
    private var timer: Timer?
    
    init(store: Store<BeeSafeState>) {
        self.store = store
        store.subscribe(self) { subcription in
            return subcription.select { state in
                return state.mapState
            }
        }
    }
    
    deinit {
        store.unsubscribe(self)
    }
    
    func viewDidLoad() {
        updateMap(with: store.state.mapState)
        
        // Workaround - should be push notifications
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.store.dispatch(GetMarkersAction())
        }
     }
    
    func tapMapBtn() {
        store.dispatch(SwitchMapModeAction())
    }
    
    func tapCameraBtn() {
        // TODO
    }
    
    public weak var view: MapViewModelDelegate?
    
    private var rooms: [Room] = []
    private var markers: [Marker] = []

    private func updateMap(with state: MapScreenState) {
        markers = state.markers
        view?.clear()
        view?.addGroundOverlay(groundOverlay)
        rooms = []
        rooms.append(Room(polygon: corridor, degreeDanger: .none))
        rooms.append(Room(polygon: lifts, degreeDanger: .none))
        rooms.append(Room(polygon: canteen, degreeDanger: .none))
        rooms.append(Room(polygon: presentationRoome, degreeDanger: .none))
        
        markers.forEach { marker in
            rooms.forEach { room in
                if GMSGeometryContainsLocation(marker.location, room.polygon.path!, false) {
                    room.increaseDanger()
                }
            }
        }

        switch state.mapType {
        case .markers:
            updateMapWithMarkers()
        case .temperature:
            updateMapWithHeatMap()
        }
    }
    
    private func updateMapWithMarkers() {
        view?.switchToMarkers()
        let res = markers.map { marker -> GMSMarker in
            let googleMarker = GMSMarker(position: marker.location)
            googleMarker.title = marker.note
            googleMarker.icon = marker.dangerType.image
            return googleMarker
        }
        
        view?.addMarkers(res)
    }
    
    private func updateMapWithHeatMap() {
        view?.switchToHeatmap()
        let res = rooms.map { room -> GMSPolygon in
            let poly = room.polygon
            poly.geodesic = true
            poly.fillColor = room.degreeDanger.color
            return poly
        }
        
        view?.addRooms(res)
    }
}

extension MapViewModelImpl: StoreSubscriber {
    func newState(state: MapScreenState) {
            DispatchQueue.main.async {
                self.updateMap(with: state)
            }
    }
}

// Map objects and overlays
private extension MapViewModelImpl {
    var canteen: GMSPolygon {
        return GMSPolygon(path: GMSPath.rectangle(
            point1:
            CLLocationCoordinate2D(latitude: 1.2880744, longitude: 103.8477180),
            
            point2:
            CLLocationCoordinate2D(latitude: 1.2880160, longitude: 103.847810),
            
            point3:
            CLLocationCoordinate2D(latitude: 1.2879479, longitude: 103.847771),
            
            point4:
            CLLocationCoordinate2D(latitude: 1.2880107, longitude: 103.847674)
            )
        )
    }
    
    var lifts: GMSPolygon {
        return GMSPolygon(path: GMSPath.rectangle(
            southWest:
            CLLocationCoordinate2D(latitude: 11.2869514, longitude: 103.8479035),
            northenEast:
            CLLocationCoordinate2D(latitude: 11.2877114, longitude: 103.8478035))
        )
    }
    
    var corridor: GMSPolygon {
        return GMSPolygon(path: GMSPath.rectangle(
            point1:
            CLLocationCoordinate2D(latitude: 1.2880160, longitude: 103.847810),
            
            point2:
            CLLocationCoordinate2D(latitude: 1.2879709, longitude: 103.847890),
            
            point3:
            CLLocationCoordinate2D(latitude: 1.2877599, longitude: 103.847751),
            
            point4:
            CLLocationCoordinate2D(latitude: 1.2878029, longitude: 103.847671)
            )
        )
    }
    
    var presentationRoome: GMSPolygon {
        return GMSPolygon(path: GMSPath.rectangle(
            point1:
            CLLocationCoordinate2D(latitude: 1.2880507, longitude: 103.847604),

            point2:
            CLLocationCoordinate2D(latitude: 1.2879479, longitude: 103.847771),

            point3:
            CLLocationCoordinate2D(latitude: 1.2878029, longitude: 103.847671),
            
            point4:
            CLLocationCoordinate2D(latitude: 1.2879079, longitude: 103.847524)
            )
        )
    }
    
    var groundOverlay: GMSGroundOverlay {
        let southWest = CLLocationCoordinate2D(latitude: 1.2878514, longitude: 103.8479035)
        let northEast = CLLocationCoordinate2D(latitude: 1.2880943, longitude: 103.8475332)
        let overlayBounds = GMSCoordinateBounds(coordinate: southWest, coordinate: northEast)
        
        let icon = UIImage(named: "plan")
        
        let overlay = GMSGroundOverlay(bounds: overlayBounds, icon: icon)
        overlay.bearing = 123
        overlay.opacity = 0.8
        return overlay
    }

}

extension Marker {
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

extension MarkerType {
    var image: UIImage {
        switch self {
        case .water:
            return UIImage(named: "spillage")!
        default:
            return UIImage(named: "tripping")!
        }
    }
}

extension  DangerDegree {
    var color: UIColor {
        switch self {
        case .none:
            return UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.1)
        case .light:
            return UIColor(displayP3Red: 0, green: 255, blue: 0, alpha: 0.2)
        case .medium:
            return UIColor(displayP3Red: 255, green: 255, blue: 0, alpha: 0.3)
        case .heavy:
            return UIColor(displayP3Red: 255, green: 0, blue: 0, alpha: 0.4)
        }
    }
}
