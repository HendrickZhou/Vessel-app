//
//  Communication.swift
//  Vessel
//
//  Created by Zhou Hang on 10/10/24.
//

import CoreBluetooth

import AVFoundation

var audioPlayer: AVAudioPlayer?

func playAudio(audioData: Data) {
    do {
        // Initialize the audio player with the accumulated audio data
        audioPlayer = try AVAudioPlayer(data: audioData)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        print("Playing audio from memory.")
    } catch {
        print("Failed to play audio: \(error)")
    }
}

class AXData {
    
    func handleData() {
        
    }
}

class NovaDeviceInfo {
    var registeredPeripheral: UUID?
    var AXServiceID : CBUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    var AXCharacteristicID: CBUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    var keyOfID = "Nova-id"
    
    init() {
        if let idstr = UserDefaults.standard.string(forKey: keyOfID) {
            registeredPeripheral = UUID(uuidString: idstr)
        }
    }
    
    func saveKV() {
        if let pId = registeredPeripheral {
            UserDefaults.standard.set(pId.uuidString, forKey: keyOfID)
        }
    }
    
    func register(pId: UUID) {
        registeredPeripheral = pId
        saveKV()
    }
    
    func getID() -> UUID?{
        return registeredPeripheral
    }
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral!
    var deviceInfo : NovaDeviceInfo!
    
    var audioData = Data()
    
    var lastCnt : Int = 0
    
    @Published var isAudioReady = false
    
    @Published var discoveredPeripherals: [CBPeripheral] = []
    
    // MARK: - Delegate, Manager
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        deviceInfo = NovaDeviceInfo()
    }
    
    // CBCentralManagerDelegate method
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .poweredOn:
            startScanning()
        case .poweredOff:
            print("Bluetooth is Off")
        case .resetting:
            print("Bluetooth is Resetting")
        case .unauthorized:
            print("Bluetooth is Unauthorized")
        case .unsupported:
            print("Bluetooth is Unsupported")
        case .unknown:
            print("Bluetooth status is Unknown")
        @unknown default:
            print("Unknown state")
        }
    }
    
    
    // TODO add recovery from disconnect
    
    // Called when a peripheral is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
//        if let pId = deviceInfo.getID() { // AUTO connect
//            if pId == peripheral.identifier {
//                centralManager.connect(peripheral, options: nil) // TODO add options
//                connectedPeripheral = peripheral
//            }
//        } else { // no registered, add to list
            if !discoveredPeripherals.contains(peripheral) {
                DispatchQueue.main.async {
                    self.discoveredPeripherals.append(peripheral)
                }
            }
//        }
    }
    
    
    // This method is called when the connection attempt fails
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "unknown device")")
        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
        // Handle reconnection or error handling here if needed
    }
    
    // Called when the device is su ccessfully connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unnamed Device")")
        deviceInfo.register(pId: peripheral.identifier)
        central.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices([deviceInfo.AXServiceID])
    }
    
    // MARK: - Delegate, Peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == deviceInfo.AXServiceID {
                print("Discovered AX Service")
                peripheral.discoverCharacteristics([deviceInfo.AXCharacteristicID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered Characteristic: \(characteristic.uuid)")
            
            // Optionally, subscribe to notifications if characteristic supports it
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error receiving data: \(error!.localizedDescription)")
            return
        }
        
        print("receiving data")
        if let data = characteristic.value {
            // Handle the received binary data (which is part of the .wav file)
            handleAudioDataChunk(data)
        }
    }
    
    func handleAudioDataChunk(_ chunk: Data) {
        // Append the received chunk to the overall audio data
        audioData.append(chunk)
        print("cnt:")
        print(audioData.count)
        print("lastcnt:")
        print(lastCnt)
        
        // For demonstration, assuming the audio data is complete at some point
                if audioData.count == 159232 { // Example condition to simulate completion
                    
                    isAudioReady = true  // Notify UI that the audio is ready
                    playAudio(audioData: audioData)
                }
        lastCnt = audioData.count
        
        // Once you have all the data, you can save or play it
        // If you're streaming, you can handle playing audio continuously
    }
    
    // MARK: - INTENT
    // Start scanning for BLE devices
    func startScanning() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    // Connect to a peripheral from UI
    func connectToDevice(at index: Int) {
        let peripheral = discoveredPeripherals[index]
        centralManager.connect(peripheral, options: nil)
    }
    
    // MARK: - FEEDBACK
    func routeToManual() {
        // notify the UI that we need to let user select device
    }

}

