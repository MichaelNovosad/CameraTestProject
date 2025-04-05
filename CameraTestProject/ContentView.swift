//
//  ContentView.swift
//  CameraTestProject
//
//  Created by Michael Novosad on 05.04.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showCamera = false

    var body: some View {
        NavigationView { // Optional, but good for titles etc.
            VStack {
                Spacer()
                Text("Basic Camera App")
                    .font(.title)
                Spacer()
                Button {
                    showCamera = true
                } label: {
                    Label("Open Camera", systemImage: "camera.fill")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
            }
            .navigationTitle("Camera Demo")
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(isPresented: $showCamera)
            }
            // For older iOS versions or different presentation style:
            // .sheet(isPresented: $showCamera) {
            //     CameraView(isPresented: $showCamera)
            // }
        }
    }
}

#Preview {
    ContentView()
}
