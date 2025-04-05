//
//  ContentView.swift
//  CameraTestProject
//
//  Created by Michael Novosad on 05.04.2025.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewControllerRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        previewLayer.frame = viewController.view.bounds
        viewController.view.layer.addSublayer(previewLayer)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        previewLayer.frame = uiViewController.view.bounds
    }
}

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isCameraReady = false
    
    var body: some View {
        ZStack {
            if isCameraReady {
                CameraPreview(previewLayer: cameraManager.getPreviewLayer())
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            if cameraManager.isProcessing {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("Processing...")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            }
            
            if let image = cameraManager.capturedImage {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                    
                    HStack(spacing: 50) {
                        Button(action: {
                            cameraManager.discardPhoto()
                        }) {
                            Image(systemName: "trash")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            cameraManager.savePhoto()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.7))
            } else if !cameraManager.isProcessing {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 50) {
                        Button(action: {
                            cameraManager.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            cameraManager.capturePhoto()
                        }) {
                            Circle()
                                .frame(width: 70, height: 70)
                                .foregroundColor(.white)
                                .overlay(
                                    Circle()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.black)
                                )
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            requestCameraPermission()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    cameraManager.start()
                    isCameraReady = true
                }
            } else {
                print("Camera permission denied")
            }
        }
    }
}

#Preview {
    ContentView()
}
