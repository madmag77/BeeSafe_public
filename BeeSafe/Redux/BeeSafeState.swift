//
//  BeeSafeState.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 18/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import Foundation
import ReSwift

struct BeeSafeState: StateType {
    var mapState: MapScreenState = MapScreenState()
    var cameraState: CameraScreenState = CameraScreenState()
    var photoState: PhotoScreenState = PhotoScreenState()
}

struct CameraScreenState: Codable {
}

struct PhotoScreenState: Codable {
    var marker: Marker = Marker(id: 0, lat: 0, lon: 0, dangerDegree: .none, note: "", dangerType: .water)
    var sentResult: String? // Workaround - should be enum with error and success
}

enum MapType: Int, Codable {
    case markers = 0
    case temperature = 1
}

enum MarkerType: Int, Codable {
    case water = 0
    case stairs = 1
    case confinedSpace = 2
}

enum DangerDegree: Int, Codable {
    case none = 0
    case light = 1
    case medium = 2
    case heavy = 3
}

struct Marker: Codable {
    let id: Int
    let lat: Double
    let lon: Double
    let dangerDegree: DangerDegree
    let note: String?
    let dangerType: MarkerType
}

struct MapScreenState: Codable {
    var mapType: MapType = MapType.markers
    var markers: [Marker] = []
}

