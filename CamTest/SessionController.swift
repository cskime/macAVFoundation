//
//  CameraSession.swift
//  CamTest
//
//  Created by chamsol kim on 17/07/2019.
//  Copyright © 2019 chamsol kim. All rights reserved.
//
//  AVFoundation Session Operation



import Cocoa
import AVFoundation

enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

class SessionController {
    private let session = AVCaptureSession()
    private var sessionSetup: SessionSetupResult = .success
    
    init() {
        verifyAuthorization(for: .video)
    }
    
    private func verifyAuthorization(for mediaType: AVMediaType) {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            NSLog("Video Authorized")
            break
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                if granted {
                    NSLog("Video Authorized")
                } else {
                    NSLog("Video not authorized")
                    self.sessionSetup = .notAuthorized
                }
            }
            
        default:
            // The user has previously denied access.
            NSLog("Video not authorized")
            sessionSetup = .notAuthorized
        }
    }
    
    func startSession() {
        guard sessionSetup == .success, !session.isRunning else {
            NSLog("Session cannot start")
            return
        }
        
        session.startRunning()
    }
    
    func stopSession() {
        guard session.isRunning else {
            NSLog("Session is not running")
            return
        }
        
        session.stopRunning()
    }
    
    func configureSessionInput(input: AVCaptureInput) {
        guard sessionSetup == .success else {
            NSLog("Camera permission is not allowed")
            return
        }
        
        session.beginConfiguration()
        
        // Configure Input
        guard session.canAddInput(input) else {
            sessionSetup = .configurationFailed
            session.commitConfiguration()
            NSLog("The input cannot be added")
            return
        }
        session.addInput(input)
        session.commitConfiguration()
    }
    
    func configureSessionOutput(output: AVCaptureOutput, preset: AVCaptureSession.Preset) {
        guard sessionSetup == .success else {
            NSLog("Camera permission is not allowed")
            return
        }
        
        session.sessionPreset = preset
        session.beginConfiguration()
        
        // Configure Input
        guard session.canAddOutput(output) else {
            sessionSetup = .configurationFailed
            session.commitConfiguration()
            NSLog("The output cannot be added")
            return
        }
        
        session.addOutput(output)
        session.commitConfiguration()
    }
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    func setPreviewLayer(at view: NSView) {
        if view.layer == nil {
            view.layer = CALayer()
        }
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        if let connect = previewLayer.connection, connect.isVideoMirroringSupported {
            connect.automaticallyAdjustsVideoMirroring = false
            connect.isVideoMirrored = true
        } else {
            NSLog("Can't filp mirrored video of preview layer because not connected. Set preview layer after session input and output is connected.")
        }
        previewLayer.frame = view.bounds
        view.layer?.addSublayer(previewLayer)
    }
    
    func updatePreviewLayer(frame: NSRect) {
        previewLayer.frame = frame
    }
}

class SessionInput {
    private var mediaType = AVMediaType.video
    
    init(for mediaType: AVMediaType) {
        self.mediaType = mediaType
    }
    
    func createDefaultDeviceInput() -> AVCaptureDeviceInput? {
        var input: AVCaptureDeviceInput? = nil
        // Find Device
        guard let videoDevice = AVCaptureDevice.default(for: mediaType) else {
            print("Default device is unavailable.")
            return input
        }
        
        // Input Device
        do {
            input = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Couldn't create device input: \(error)")
            return input
        }
        
        return input
    }
}

class SessionImageOutput {
    private let imageOutput = AVCaptureStillImageOutput()
    
    init() {
        // Apple Document - pidxe format type
        // https://developer.apple.com/documentation/corevideo/kcvpixelformattype_32bgra
        imageOutput.outputSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA];
    }
    
    func getImageOutput() -> AVCaptureStillImageOutput {
        return imageOutput
    }
    
    func capturePNGImage(path: URL) {
        let connection = imageOutput.connections.filter {
            return $0.inputPorts[0].mediaType == .video
        }[0]
        
        // flip mirrored image
        connection.isVideoMirrored = true
        
        imageOutput.captureStillImageAsynchronously(from: connection) { (imageSampleBuffer: CMSampleBuffer?, error: Error?) in
            if let image = imageSampleBuffer?.convertToNSImage()
            {
                if image.pngWrite(to: path) {
                    NSLog("Write Success")
                } else {
                    NSLog("Write Fail")
                }
            }
        }
    }
}

extension CMSampleBuffer {
    // AVCaptureStillImageOutput capture image
    // When use captureStillImageAsynchronously(connection:completionHandler:), convert CMSampleBuffer to NSImage.
    // https://stackoverflow.com/questions/34605236/avcapturestillimageoutput-pngstillimagensdatarepresentation
    
    func convertToNSImage() -> NSImage? {
        guard let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        
        if CVPixelBufferLockBaseAddress(imageBuffer, .readOnly) != kCVReturnSuccess { return nil }
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(imageBuffer),
            width: CVPixelBufferGetWidth(imageBuffer),
            height: CVPixelBufferGetHeight(imageBuffer),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let quartzImage = context!.makeImage() else { return nil }
        let nsImage = NSImage(cgImage: quartzImage, size: .zero)
        return nsImage
    }
}

extension NSImage {
    // NSImage write to png file.
    // https://soooprmx.com/archives/2403
    
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    // File save on macOS with swift
    // Only url using Filemanager.default verified
    // Can't write at "Desktop" folder or other path because have not permission
    // https://stackoverflow.com/questions/39925248/swift-on-macos-how-to-save-nsimage-to-disk
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
