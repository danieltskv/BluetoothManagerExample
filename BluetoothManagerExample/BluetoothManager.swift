//
//  BluetoothManager.swift
//  BluetoothManagerExample
//
//  Created by Daniel Tsirulnikov on 7/30/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

import Foundation
import CoreBluetooth

/// A simple protocol to update the UI when an event occurs
protocol BluetoothManagerUIDelegate: class {
    func updateInterface()
}

class BluetoothManager: NSObject {
    
    // MARK: Properties

    static let shared = BluetoothManager()
    
    weak var delegate: BluetoothManagerUIDelegate?

    private var centralManager: CBCentralManager!
    
    var peripherals = [CBPeripheral]()

    var isScanning: Bool {
        return centralManager.isScanning
    }
    
    // MARK: Initialization

    override init() {
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: Methods

    func scanForPeripherals() {
        print("[BluetoothManager] Scan started")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        print("[BluetoothManager] Scan stopped")
        centralManager.stopScan()
    }
    
    func connect(_ peripheral: CBPeripheral) {
        print("[BluetoothManager] Sending a connect request to peripheral \(peripheral)")
        centralManager.connect(peripheral, options: nil)
    }
    
    /// This method retrieves previously connected peripherals and tries to re-connect them without `scanForPeripherals`.
    /// Because `connect()` calls do not time out (per Apple documentation), the central manager will wait until a
    // device is in range, and then will try to connect to it.
    /// When a device connects, the `didConnect()` delegate method is called.
    func connectToKnownPeripherals() {
        // Retrieve peripheral identifiers from devices we connected before
        let knownPeripheralIdentifiers = self.knownPeripheralIdentifiers
        guard !knownPeripheralIdentifiers.isEmpty else {
            print("[BluetoothManager] No known peripherals found")
            return
        }
        
        // Retrieve the peripheral objects from the identifiers
        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: knownPeripheralIdentifiers)
        
        print("[BluetoothManager] Known peripherals \(knownPeripherals)")

        peripherals.append(contentsOf: knownPeripherals)
        delegate?.updateInterface()

        knownPeripherals.forEach { (peripherals) in
            connect(peripherals)
        }
    }
    
}

// MARK: - Known Peripherals

extension BluetoothManager {
    
    private static let knownPeripheralsUserDefaultsKey = "KnownPeripheralsIdentifiers"
    
    /// Retrieve all previously stored peripheral identifiers
    private var knownPeripheralIdentifiers: [UUID] {
        guard let identifiers = UserDefaults.standard.array(forKey: BluetoothManager.knownPeripheralsUserDefaultsKey) as? [String] else { return [] }
        return identifiers.compactMap { UUID(uuidString: $0) }
    }
    
    /// Store a peripheral identifiers
    private func store(_ peripheral: CBPeripheral) {
        var identifiers = UserDefaults.standard.array(forKey: BluetoothManager.knownPeripheralsUserDefaultsKey) as? [String] ?? [String]()
        
        // Do not store duplicate identifiers
        guard !identifiers.contains(where: { $0 == peripheral.identifier.uuidString }) else {
            return
        }
        
        identifiers.append(peripheral.identifier.uuidString)
        
        UserDefaults.standard.set(identifiers, forKey: BluetoothManager.knownPeripheralsUserDefaultsKey)
    }
    
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("[BluetoothManager] Did update Central Manager state: \(central.state.description)")

        if central.state == .poweredOn {
            connectToKnownPeripherals()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else {
            return
        }
        
        guard !peripherals.contains(where: { $0.identifier == peripheral.identifier }) else {
            return
        }
        
        print("[BluetoothManager] Did discovered peripheral \(peripheral) rssi \(RSSI)")

        peripherals.insert(peripheral, at: 0)
        delegate?.updateInterface()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[BluetoothManager] Did connect peripheral \(peripheral)")
        delegate?.updateInterface()
        
        // We store the connected peripheral in order to automaticly connect to it next time
        store(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[BluetoothManager] Did disconnect peripheral \(peripheral)")
        delegate?.updateInterface()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[BluetoothManager] Did failed to connect peripheral \(peripheral)")
        delegate?.updateInterface()
    }
    
}

// MARK: - Helpers

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOn: return "Powered On"
        case .poweredOff: return "Powered Off"
        @unknown default: return "Unknown"
        }
    }
}


extension CBPeripheralState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting"
        case .disconnected: return "Disconnected"
        @unknown default: return "Unknown"
        }
    }
}
