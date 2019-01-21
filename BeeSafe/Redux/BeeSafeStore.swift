//
//  BeeSafeStore.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 18/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import Foundation
import ReSwift

let store: Store<BeeSafeState> = Store<BeeSafeState> (
    reducer: beeSafeReducer,
    state: BeeSafeState(),
    middleware: [printActionsMiddleware,
                 sendServerActionsMiddleware]
)

func beeSafeReducer(action: Action, state: BeeSafeState?) -> BeeSafeState {
    return BeeSafeState(
        mapState: mapScreenStateReducer(action: action, state: state?.mapState),
        cameraState: cameraScreenStateReducer(action: action, state: state?.cameraState),
        photoState: photoScreenStateReducer(action: action, state: state?.photoState)
    )
}

func mapScreenStateReducer(action: Action, state: MapScreenState?) -> MapScreenState {
    var state = state ?? MapScreenState()
    
    switch action {
    case let markersAction as NewMarkers:
        state.markers = markersAction.markers

    case let switchMapModeAction as SwitchMapModeAction:
        if state.mapType == .markers {
            state.mapType = .temperature
        } else {
            state.mapType = .markers
        }
    default:
        //fatalError("Unknown action = \(action)")
        break
    }
    
    return state
}

func photoScreenStateReducer(action: Action, state: PhotoScreenState?) -> PhotoScreenState {
    var state = state ?? PhotoScreenState()
    
    switch action {
    case let addMarker as AddMarker:
        state.marker = addMarker.marker
        state.sentResult = nil
    case let sentDone as SentDone:
        state.sentResult = sentDone.result
    default:
        //fatalError("Unknown action = \(action)")
        break
    }
    
    return state
}

func cameraScreenStateReducer(action: Action, state: CameraScreenState?) -> CameraScreenState {
    var state = state ?? CameraScreenState()
    
    switch action {
        
        
    default:
        //fatalError("Unknown action = \(action)")
        break
    }
    
    return state
}

func printActionsMiddleware<T>(_ directDispatch: @escaping DispatchFunction, _ getState: @escaping () -> T?) -> ((@escaping DispatchFunction) -> DispatchFunction) {
    let t: T? = nil
    return { nextDispatch in
        return {action in
            print("\(type(of: t)): \(type(of: action))")
            nextDispatch(action)
        }
    }
}

func sendServerActionsMiddleware<T>(_ directDispatch: @escaping DispatchFunction, _ getState: @escaping () -> T?) -> ((@escaping DispatchFunction) -> DispatchFunction) {
    return { nextDispatch in
        let service = MarkersService()
        return {action in
            switch action {
            case let sendAction as SendAddMarkerAction:
                service.addMarker(sendAction.marker)
                break
                
            case let _ as GetMarkersAction:
                service.getMarkers()
                break

            default:
                nextDispatch(action)
            }
        }
    }
}

protocol SendToServerActions: Action {
}

struct SendAddMarkerAction: SendToServerActions {
    let marker: Marker
}

struct GetMarkersAction: SendToServerActions {
}

struct AddMarker: Action {
     let marker: Marker
}

struct SentDone: Action {
    let result: String?
}

struct NewMarkers: Action {
    let markers: [Marker]
}

struct SwitchMapModeAction: Action {
}
