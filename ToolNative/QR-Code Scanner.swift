//
//  ViewController.swift
//  QR-Code Reader
//
//  Created by Rabea Kessler on 28.04.19.
//  Copyright © 2019 Marcin Kessler. All rights reserved.
//

import AVFoundation
import UIKit

class ScannerViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    let cameraAutorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    
    let torchButton = UIButton(type: .roundedRect)
    var settingsButton = UIButton() // for No Autorization
    
    var delegate:ScannerDelegate?
    
    var tag = ""
    var tag2 = Int()
    
    //MARK:-Einstellungen
    let feedbackType:FeedbackType = .haptic
    
    enum FeedbackType {
        case vibrate, haptic
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch cameraAutorizationStatus {
        case .denied,.restricted:
            showNoAutorization()
            
        default:
            print("Camera using is autorizated")
            setupAVCaptureSession()
        }
        
        setupUI()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        
        flashActive(toggle: false, toState: .off)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate?.scannerDidDisappear?()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        
    }
    
    @objc func dismissSelf() {
        flashActive(toggle: false, toState: .off)
        self.dismiss(animated: true) {
            self.delegate?.scannerDidDisappear?()
        }
    }
    
    @objc func flash() {
        flashActive()
    }
 
    func flashActive(toggle:Bool = true, toState:AVCaptureDevice.TorchMode = .on) {
        if let currentDevice = AVCaptureDevice.default(for: AVMediaType.video), currentDevice.hasTorch {
            do {
                try currentDevice.lockForConfiguration()
                let torchOn = !currentDevice.isTorchActive
                if !toggle {
                    if toState == .on {
                        try currentDevice.setTorchModeOn(level:0.3)
                    }
                    currentDevice.torchMode = toState
                    toState == .on ? torchButton.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal) : torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
                }else {
                    try currentDevice.setTorchModeOn(level:0.3)
                    currentDevice.torchMode = torchOn ? .on : .off
                    torchOn ? torchButton.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal) : torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
                }
                
                currentDevice.unlockForConfiguration()
            } catch {
                print("Error set TorchMode")
            }
        }
    }
    
    //MARK:- Setup UI
    
    private func setupAVCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            deviceHasNoCamera()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8,.qr,.aztec,.code128,.code39,.code39Mod43,.code93,.ean13,.pdf417,.dataMatrix,.interleaved2of5,.itf14,.upce,.face]
        } else {
            deviceHasNoCamera()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.layer.bounds
        captureSession.startRunning()
    }
    
    private func setupUI() {
        
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        
        view.backgroundColor = .secondarySystemGroupedBackground
        
        //MARK:- Close Button
        let closeButton = UIButton(type: .roundedRect)
        closeButton.frame = CGRect(x: 10, y: 10, width: 70, height: 50)
        closeButton.layer.cornerRadius = 20
        closeButton.layer.masksToBounds = true
        closeButton.backgroundColor = UIColor { (traits) -> UIColor in
            return traits.userInterfaceStyle == .dark ? .quaternaryLabel : .secondaryLabel
        }
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.setPreferredSymbolConfiguration(symbolConfiguration, forImageIn: .normal)
        closeButton.addTarget(self, action:#selector(dismissSelf) , for: .touchUpInside)
        view.addSubview(closeButton)
        
        //MARK:- Torch Button
        torchButton.frame = CGRect(x: 90, y: 10, width: 70, height: 50)
        torchButton.layer.cornerRadius = 20
        torchButton.layer.masksToBounds = true
        torchButton.backgroundColor = UIColor { (traits) -> UIColor in
            return traits.userInterfaceStyle == .dark ? .quaternaryLabel : .secondaryLabel
        }
        torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
        torchButton.setPreferredSymbolConfiguration(symbolConfiguration, forImageIn: .normal)
        torchButton.addTarget(self, action: #selector(flash) , for: .touchUpInside)
        view.addSubview(torchButton)
    }
    
    private func showNoAutorization() {
        let messageLabel = UILabel()
        messageLabel.text = """
            Keine Kameraberechtigung
            Erlauben Sie den Zugriff auf die Kamera
            """
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.boldSystemFont(ofSize: 17)
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .secondaryLabel
        view.addSubview(messageLabel)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            messageLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -40)
        ])
        
        settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        settingsButton.setTitle("  Einstellungen  ", for: .normal)
        settingsButton.layer.cornerRadius = 5
        settingsButton.layer.borderWidth = 1
        settingsButton.layer.borderColor = UIColor.secondaryLabel.cgColor
        settingsButton.setTitleColor(.secondaryLabel, for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        view.addSubview(settingsButton)
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            settingsButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0),
            settingsButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 10),
        ])
    }
    
    private func deviceHasNoCamera() {

        captureSession = nil
        
        let messageLabel = UILabel()
        messageLabel.text = """
            Scannen wird nicht unterstützt

            Ihr Gerät unterstützt das Scannen eines QR-Codes nicht. Bitte verwenden Sie ein Gerät mit einer Kamera.
            """
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.boldSystemFont(ofSize: 17)
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .secondaryLabel
        view.addSubview(messageLabel)
        messageLabel.center = view.center
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            messageLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -40)
        ])

    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            settingsButton.layer.borderColor = UIColor.secondaryLabel.cgColor
        }
    }
    
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        print("MetaData output")
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else {showAlert(title: "Fehler aufgetreten", message: """
                Readable Object can't convert to type String and captureSession.stopRunning() not call
                Please notify Marcin Kessler
                """); return }
            captureSession.stopRunning()
            
            if feedbackType == .vibrate {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }else {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
            }
            
            // Found Code
            self.dismiss(animated: true) {
                self.delegate?.foundContent(string: stringValue, tag: self.tag, tag2: self.tag2)
            }
        }
    }
}

@objc protocol ScannerDelegate {
    func foundContent(string:String, tag:String, tag2:Int)
    @objc optional func scannerDidDisappear()
}
