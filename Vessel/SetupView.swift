//
//  ContentView.swift
//  Vessel
//
//  Created by Zhou Hang on 10/10/24.
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var bleManager = BLEManager()

    var body: some View {
        VStack {
                    Text("Bluetooth Audio Receiver")
                        .font(.headline)
                    
                    if bleManager.isAudioReady {
                        Button(action: {
                            playAudio(audioData: bleManager.audioData)
                        }) {
                            Text("Play Received Audio")
                                .font(.title)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Text("Waiting for audio data...")
                            .font(.subheadline)
                            .padding()
                    }
                }

        NavigationView {
           List(bleManager.discoveredPeripherals.indices, id: \.self) { index in
               HStack {
                   Text(bleManager.discoveredPeripherals[index].name ?? "Unnamed Device")
                   Spacer()
                   Button(action: {
                       bleManager.connectToDevice(at: index)
                   }) {
                       Text("Connect")
                   }
               }
           }
           .navigationTitle("Nearby BLE Devices")
           .onAppear {
               bleManager.startScanning()
           }
       }
    }
    
}

#Preview {
    SetupView()
}
