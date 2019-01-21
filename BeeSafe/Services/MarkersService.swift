//
//  MarkersService.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 19/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import Foundation
import Alamofire

class MarkersService {
    let urlString: String = "http://?????.ap-southeast-1.compute.amazonaws.com:????/markers"
    
    func addMarker(_ marker: Marker) {
        guard let url = URL(string: urlString) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try? JSONEncoder().encode(marker)
        Alamofire.request(request).responseJSON {
            response in
            store.dispatch(SentDone(result: "OK"))
            print(response.response)
        }
    }
    
    func getMarkers() {
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        Alamofire.request(request).responseJSON {
            response in
            
            let decoder = JSONDecoder()
            guard let data = response.data else { return }
            do {
                let markers = try decoder.decode([Marker].self, from: data)
                store.dispatch(NewMarkers(markers: markers))
            } catch {
                print(error)
            }
        }
    }

}
