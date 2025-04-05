//
//  CameraViewControllerRepresentable.swift
//  CameraTestProject
//
//  Created by Michael Novosad on 05.04.2025.
//

import SwiftUI
import AVFoundation

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @ObservedObject var coordinator: CameraCoordinator // Use the passed-in coordinator

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.coordinator = coordinator // Assign coordinator to the controller

        // Set the callback in the coordinator
        coordinator.didCapturePhoto = { image in
             self.capturedImage = image
        }

        // Give coordinator a reference back to the controller
        coordinator.cameraViewController = controller

        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update the controller if needed, e.g., changing camera device (not needed for basic)
    }

    // The coordinator is already created and passed in via @StateObject in CameraView
    // So we don't need makeCoordinator() here if using the @StateObject approach.
    // If NOT using @StateObject, you would uncomment makeCoordinator and manage it here.
    // func makeCoordinator() -> CameraCoordinator {
    //     coordinator // Return the existing coordinator
    // }
}
