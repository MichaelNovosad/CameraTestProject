//
//  CameraView.swift
//  CameraTestProject
//
//  Created by Michael Novosad on 05.04.2025.
//

import SwiftUI
import AVFoundation // Import for checking authorization status
import Photos       // Import for checking authorization status

struct CameraView: View {
    @Binding var isPresented: Bool
    @State private var capturedImage: UIImage? = nil
    @State private var showingPreview = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""

    // Use a single source of truth for the representable view controller
    @StateObject private var cameraCoordinator = CameraCoordinator()

    var body: some View {
        ZStack {
            // Only show the camera controller if we don't have a captured image
            if !showingPreview {
                 CameraViewControllerRepresentable(
                     capturedImage: $capturedImage,
                     coordinator: cameraCoordinator // Pass the coordinator
                 )
                .ignoresSafeArea() // Make it full screen

                VStack {
                    Spacer() // Pushes button to the bottom
                    Button {
                        // Ask the coordinator to trigger capture
                        cameraCoordinator.triggerCapture()
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray, lineWidth: 3)
                                    .frame(width: 60, height: 60)
                            )
                            .padding(.bottom, 30)
                    }
                }
            } else if let image = capturedImage {
                // Show the preview view when an image is captured
                PhotoPreviewView(
                    image: image,
                    onSave: {
                        // Save logic
                        savePhoto(image)
                        // Option 1: Dismiss after saving
                        // isPresented = false
                        // Option 2: Go back to camera after saving
                         resetCapture()
                    },
                    onDiscard: {
                        // Discard logic - just reset the state
                        resetCapture()
                    }
                )
            }
        }
        .onAppear(perform: checkPermissions) // Check permissions when view appears
        .onChange(of: capturedImage) { _, newValue in
             // When capturedImage changes, update showingPreview state
            showingPreview = (newValue != nil)
        }
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text(permissionAlertMessage),
                dismissButton: .default(Text("OK"), action: {
                    isPresented = false // Dismiss the camera view if permissions denied
                })
            )
        }
    }

    private func checkPermissions() {
        // Camera Permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
             checkPhotoLibraryPermission() // Proceed to check photo library permission

        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                         checkPhotoLibraryPermission() // Check library permission after granting camera
                    }
                } else {
                    DispatchQueue.main.async {
                        showPermissionAlert(message: "Camera access is required to take photos. Please enable it in Settings.")
                    }
                }
            }

        case .denied, .restricted: // The user has previously denied access or it's restricted.
            showPermissionAlert(message: "Camera access has been denied or restricted. Please enable it in Settings to take photos.")
            return // Don't proceed if camera access is denied

        @unknown default:
            fatalError("Unknown camera authorization status")
        }
    }

    private func checkPhotoLibraryPermission() {
         // Photo Library Add Permission (only need add permission)
         let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
         switch status {
         case .authorized, .limited: // Already authorized or limited (iOS 14+)
             // Permissions are sufficient
             break
         case .notDetermined:
             PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                 if newStatus != .authorized && newStatus != .limited {
                     DispatchQueue.main.async {
                         showPermissionAlert(message: "Photo Library access is recommended to save photos. You can grant access in Settings.")
                         // We can still proceed without save permission, just warn
                     }
                 }
             }
         case .denied, .restricted:
            // Warn the user they won't be able to save, but let them continue taking photos
             showPermissionAlert(message: "Photo Library access is denied. You won't be able to save photos. You can grant access in Settings.")
            // Don't block the camera, just alert
         @unknown default:
             fatalError("Unknown photo library authorization status")
         }
     }


    private func showPermissionAlert(message: String) {
        permissionAlertMessage = message
        showingPermissionAlert = true
    }

    private func resetCapture() {
        capturedImage = nil
        showingPreview = false
    }

    private func savePhoto(_ image: UIImage) {
        // Check permission again before saving (optional, but good practice)
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard status == .authorized || status == .limited else {
            print("Error: Photo library access denied.")
            // Optionally show an alert here
            resetCapture() // Go back to camera view even if save fails
            return
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Photo saved successfully!")
                    // Decide whether to dismiss or allow taking another photo
                    // Option 1: Dismiss
                    // self.isPresented = false
                    // Option 2: Allow taking another photo (already handled by resetCapture called in the closure)
                } else if let error = error {
                    print("Error saving photo: \(error.localizedDescription)")
                    // Optionally show an error alert
                }
                // Ensure UI updates happen after save attempt
                resetCapture()
            }
        }
    }
}

// Coordinator class to handle communication from UIKit to SwiftUI
class CameraCoordinator: NSObject, AVCapturePhotoCaptureDelegate, ObservableObject {
    // Use a weak reference to avoid retain cycles if CameraViewController holds a strong ref
    weak var cameraViewController: CameraViewController?

    // Callback to SwiftUI View
    var didCapturePhoto: ((UIImage) -> Void)?

    func triggerCapture() {
        cameraViewController?.capturePhoto()
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Error processing captured photo data.")
            return
        }

        // Use the callback to pass the image back to SwiftUI
        DispatchQueue.main.async {
             self.didCapturePhoto?(image)
        }
    }
}


#Preview {
    // Need a dummy binding for preview
    CameraView(isPresented: .constant(true))
}
