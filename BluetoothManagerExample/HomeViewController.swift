//
//  HomeViewController.swift
//  BluetoothManagerExample
//
//  Created by Daniel Tsirulnikov on 7/30/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

import UIKit
import CoreBluetooth

class HomeViewController: UITableViewController {
    
    @IBOutlet weak var scanButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BluetoothManager.shared.delegate = self
    }

    @IBAction func toggleScan(_ sender: Any) {
        if BluetoothManager.shared.isScanning {
            BluetoothManager.shared.stopScan()
            scanButton.title = NSLocalizedString("Scan", comment: "")
        } else {
            BluetoothManager.shared.scanForPeripherals()
            scanButton.title = NSLocalizedString("Stop", comment: "")
        }
    }
    
    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BluetoothManager.shared.peripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath)

        let peripheral = BluetoothManager.shared.peripherals[indexPath.row]
        
        cell.textLabel?.text = peripheral.name
        cell.detailTextLabel?.text = peripheral.state.description

        switch peripheral.state {
        case .connecting:
            cell.detailTextLabel?.textColor = UIColor.orange
        case .connected:
            cell.detailTextLabel?.textColor = UIColor.green
        default:
            cell.detailTextLabel?.textColor = UIColor.red
        }
        
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = BluetoothManager.shared.peripherals[indexPath.row]
        BluetoothManager.shared.connect(peripheral)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - BluetoothManagerUIDelegate

extension HomeViewController: BluetoothManagerUIDelegate {
    func updateInterface() {
        self.tableView.reloadData()
    }
}
