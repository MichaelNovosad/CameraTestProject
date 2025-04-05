//
//  PhotoPreviewView.swift
//  CameraTestProject
//
//  Created by Michael Novosad on 05.04.2025.
//

import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ZStack {
            // Background for the preview
            Color.black.ignoresSafeArea()

            // Display the captured image
            Image(uiImage: image)
                .resizable()
                .scaledToFit() // Fit within the screen bounds
                .ignoresSafeArea()


            // Overlay controls at the bottom
            VStack {
                Spacer() // Pushes buttons to the bottom
                HStack {
                    Button {
                        onDiscard()
                    } label: {
                        Label("Retake", systemImage: "xmark.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }

                    Spacer() // Pushes buttons apart

                    Button {
                        onSave()
                    } label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    // Create a dummy UIImage for preview
    let dummyImage = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { ctx in
        UIColor.blue.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
    }
    return PhotoPreviewView(image: dummyImage, onSave: { print("Save Tapped") }, onDiscard: { print("Discard Tapped") })
}
