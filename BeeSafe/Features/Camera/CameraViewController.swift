//
//  CameraViewController.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 18/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit
import CoreLocation

var capturedImageGlobal: UIImage = UIImage()

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var previewView: UIView = UIView()
    var rootLayer: CALayer! = nil
    var mapBtn: UIButton = UIButton()
    var takePhotoBtn: UIButton = UIButton()
    var _capturedImage: UIImage = UIImage()
    var _capturedImageLock: NSLock = NSLock()
    var capturedImage: UIImage {
        get {
            _capturedImageLock.lock()
            defer { _capturedImageLock.unlock() }
            return _capturedImage
        }
        
        set {
            _capturedImageLock.lock()
            defer { _capturedImageLock.unlock() }
            _capturedImage = newValue
        }
    }
    var previousGuess: String = ""
    private var locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    var bufferSize: CGSize = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()

        store.dispatch(GetMarkersAction()) // We want to download markers as earlier as possible
        
        view.addSubview(previewView)
        previewView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 1
        locationManager.startUpdatingLocation()
        locationManager.delegate = self

        setupAVCapture()
        initUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    
    func startCaptureSession() {
       captureSession.startRunning()
    }
    
    func teardownAVCapture() {
        captureSession.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
        videoPreviewLayer = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("frame dropped")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        capturedImage = sampleBuffer.image()!
    }
    
    // Convert CIImage to CGImage
    
    private func initUI() {
        view.addSubview(mapBtn)
        mapBtn.setImage(UIImage(named: "mapIcon"), for: .normal)
        mapBtn.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(view).offset(-40)
            make.bottom.equalTo(view).offset(-40)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        mapBtn.addTarget(self, action: #selector(CameraViewController.tapGoMapBtn(_:)), for: .touchUpInside)
        
        view.addSubview(takePhotoBtn)
        takePhotoBtn.setImage(UIImage(named: "shutter"), for: .normal)
        takePhotoBtn.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).offset(-40)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        takePhotoBtn.addTarget(self, action: #selector(CameraViewController.tapTakePhotoBtn(_:)), for: .touchUpInside)

    }
    
    func setupAVCapture() {
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video),
            let input = try? AVCaptureDeviceInput(device: captureDevice) else {
                print("ERROR of creating of AVCaptureDeviceInput")
                return
        }
        
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480 // Model image size is smaller.
        
        // Add a video input
        guard captureSession.canAddInput(input) else {
            print("Could not add video device input to the session")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            captureSession.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        captureConnection?.videoOrientation = .portrait
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        captureSession.commitConfiguration()
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        previewView.layer.addSublayer(videoPreviewLayer!)
        rootLayer = previewView.layer

    }
    
    @objc
    private func tapGoMapBtn(_ sender: NSObject) {
        performSegue(withIdentifier: "cameraToMap", sender: self)
    }
    
    @objc
    private func tapTakePhotoBtn(_ sender: NSObject) {
        capturedImageGlobal = capturedImage
        var degree: DangerDegree = .none
        var dangerType: MarkerType = MarkerType.confinedSpace
        
        if previousGuess.range(of: "High Tripping") != nil {
            dangerType = .stairs
            degree = .heavy
        } else if previousGuess.range(of: "High Spillage") != nil {
            dangerType = .water
            degree = .light
        }
        
        store.dispatch(AddMarker(marker: Marker(id: 1,
                                        lat: currentLocation?.coordinate.latitude ?? 0.0,
                                        lon: currentLocation?.coordinate.longitude ?? 0.0,
                                        dangerDegree: degree,
                                        note: previousGuess,
                                        dangerType: dangerType)))
        
        performSegue(withIdentifier: "CameraToPhotoSend", sender: self)
    }

    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }

}

extension CMSampleBuffer {
    func image(orientation: UIImage.Orientation = .up,
               scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)
            
            return UIImage(ciImage: ciImage,
                           scale: scale,
                           orientation: orientation)
        }
        
        return nil
    }
}

extension CameraViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first!
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.

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
