//
//  PhotoSendViewController.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 19/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import UIKit
import Alamofire
import ReSwift

class PhotoSendViewController: UIViewController {
    private var imagePreview: UIImageView = UIImageView()
    private var sendBtn: UIButton = UIButton()
    private var dangerLabel: UILabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(imagePreview)
        imagePreview.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
        imagePreview.image = capturedImageGlobal
        imagePreview.contentMode = .scaleAspectFill
        view.addSubview(sendBtn)
        sendBtn.setImage(UIImage(named: "send"), for: .normal)
        sendBtn.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).offset(-40)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        sendBtn.addTarget(self, action: #selector(tapSendBtn(_:)), for: .touchUpInside)
        
        view.addSubview(dangerLabel)
        dangerLabel.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(view)
            make.top.equalTo(view).offset(40)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.height.equalTo(30)
        }
        
        if store.state.photoState.marker.dangerDegree != .none {
            dangerLabel.backgroundColor = .red
            dangerLabel.textColor = .white
            dangerLabel.font = dangerLabel.font.withSize(16.0)
            dangerLabel.text = store.state.photoState.marker.dangerType == .water ? "High Spillage Risk. Risk level 5": "High Tripping Hazard. Risk level 5";
        }
        
        store.subscribe(self) { subcription in
            return subcription.select { state in
                return state.photoState
            }
        }
    }
    
    deinit {
        store.unsubscribe(self)
    }

    
    @objc
    private func tapSendBtn(_ sender: NSObject) {
        let marker = store.state.photoState.marker
        store.dispatch(SendAddMarkerAction(marker: marker))
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

extension PhotoSendViewController: StoreSubscriber {
    func newState(state: PhotoScreenState) {
        if state.sentResult == "OK" {
            store.dispatch(SentDone(result: nil))
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
                
            }
        }
    }
}
