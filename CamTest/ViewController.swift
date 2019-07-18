//
//  ViewController.swift
//  CamTest
//
//  Created by chamsol kim on 16/07/2019.
//  Copyright © 2019 chamsol kim. All rights reserved.
//

// Mac Camera Usage Setting
// Project - Capabilities - App Sandbox - Hardware : Camera Check
//https://stackoverflow.com/questions/47315531/avcapturedevice-on-macos

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    var camSession: SessionController!
    var videoInput: SessionInput!
    var imageOutput: SessionImageOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        camSession = SessionController()
        videoInput = SessionInput(for: .video)
        imageOutput = SessionImageOutput()
        
        camSession.setPreviewLayer(at: self.view)
        
        if let input = videoInput.createDefaultDeviceInput() {
            camSession.configureSessionInput(input: input)
            camSession.configureSessionOutput(output: imageOutput.getImageOutput(), preset: .photo)
        }
        
        camSession.startSession()
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        camSession.updatePreviewLayer(frame: view.bounds)
    }
    
    @IBAction func capture(_ sender: Any) {
        if let urlPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("my-image.png") {
            imageOutput.capturePNGImage(path: urlPath)
        }
    }
}





