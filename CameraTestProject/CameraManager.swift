//
//  CameraManager.swift
//  CameraTestProject
//
//  Created by Michael Novosad on 05.04.2025.
//

import AVFoundation
import Photos
import UIKit

class CameraManager: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var currentCamera: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    
    @Published var capturedImage: UIImage?
    @Published var isProcessing: Bool = false
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera(position: AVCaptureDevice.Position = .back) -> Bool {
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: position) else {
            print("No camera available")
            return false
        }
        
        currentCamera = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            photoOutput.isHighResolutionCaptureEnabled = false // Reduce processing load
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            return true
        } catch {
            print("Error setting up camera: \(error)")
            return false
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    func start() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput,
              captureSession.isRunning,
              !photoOutput.connections.isEmpty else {
            print("Cannot capture photo: session not ready or no connections")
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg]) // Use JPEG instead of raw
        
        sessionQueue.async {
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        start()
    }
    
    func switchCamera() {
        guard let currentPosition = currentCamera?.position else { return }
        sessionQueue.async {
            self.stop()
            self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
            let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
            if self.setupCamera(position: newPosition) {
                self.start()
            }
        }
    }
    
    func savePhoto() {
        guard let image = capturedImage else { return }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                if let error = error {
                    print("Error saving photo: \(error)")
                } else if success {
                    print("Photo saved successfully")
                    self.capturedImage = nil
                }
            }
        }
        start()
    }
    
    func discardPhoto() {
        DispatchQueue.main.async {
            self.capturedImage = nil
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        sessionQueue.async {
            if let error = error {
                print("Error capturing photo: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("Failed to get image data")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.capturedImage = image
                self.isProcessing = false
            }
        }
    }
}
