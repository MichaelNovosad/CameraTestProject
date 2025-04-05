//
//  CameraViewController.swift
//  CameraTestProject
//
//  Created by Michael Novosad on 05.04.2025.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var backCamera: AVCaptureDevice?
    private var backInput: AVCaptureDeviceInput?

    // Coordinator to handle delegate methods and communication
    weak var coordinator: CameraCoordinator? // Weak reference

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Set background for areas not covered by preview
        setupCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start session asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
             self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop session asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure preview layer fills the view bounds after layout changes (e.g., rotation)
        previewLayer?.frame = view.bounds
    }


    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration() // Batch configuration changes

        // --- Input Setup ---
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Error: Could not find back camera.")
            captureSession.commitConfiguration()
            // Handle error appropriately (e.g., show alert via coordinator)
            return
        }
        backCamera = device

        do {
            backInput = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(backInput!) {
                captureSession.addInput(backInput!)
            } else {
                print("Error: Could not add camera input to session.")
                captureSession.commitConfiguration()
                return
            }
        } catch {
            print("Error creating camera input: \(error.localizedDescription)")
            captureSession.commitConfiguration()
            return
        }

        // --- Output Setup ---
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            // Ensure High Resolution Photos are enabled if available
             if photoOutput.isHighResolutionCaptureEnabled {
                 photoOutput.isHighResolutionCaptureEnabled = true
             }
        } else {
            print("Error: Could not add photo output to session.")
            captureSession.commitConfiguration()
            return
        }

        captureSession.commitConfiguration() // Apply all configuration changes

        // --- Preview Layer ---
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill // Fill the screen, cropping if necessary
        previewLayer.connection?.videoOrientation = .portrait // Set initial orientation (handle rotation if needed)
        previewLayer.frame = view.bounds // Set initial frame
        view.layer.addSublayer(previewLayer)
    }

    // --- Capture Method ---
    func capturePhoto() {
        guard let output = photoOutput else {
            print("Error: Photo output is not configured.")
            return
        }
        guard let coordinator = self.coordinator else {
            print("Error: Coordinator not set.")
            return
        }

        // Settings for the photo capture
        let photoSettings = AVCapturePhotoSettings()

        // Enable High Resolution Photo Capture if supported
        if output.isHighResolutionCaptureEnabled {
             photoSettings.isHighResolutionPhotoEnabled = true
        }

        // Use JPEG format; other formats like HEIF are available
        if output.availablePhotoCodecTypes.contains(.jpeg) {
            photoSettings.photoQualityPrioritization = output.maxPhotoQualityPrioritization // Prioritize quality over speed
        }

        // Capture the photo, delegating the result handling to the coordinator
        output.capturePhoto(with: photoSettings, delegate: coordinator)
        print("Capture triggered")
    }
}
