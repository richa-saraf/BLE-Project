//
//  ViewController.swift
//  TestCBApp
//
//  Created by Richa Saraf on 3/24/17.
//  Copyright © 2017 Richa Saraf. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var bleStatusLabel: UILabel!
    
    @IBOutlet weak var peripheralLabel: UILabel!
    
    @IBOutlet weak var periconnectLabel: UILabel!
  
    @IBOutlet weak var servicesLabel: UILabel!
    
    
    // Variable declaration
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var ServiceUUID : CBUUID!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // UUID conversions
        self.ServiceUUID = CBUUID(string: OL_Uuids.SERVICE_UUID)
        
        //Initialize Cnetral Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // CentralManagerDelegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            bleStatusLabel.text = "Powered OFF"
        case .poweredOn:
            bleStatusLabel.text = "Powered ON"
        case .unsupported:
            bleStatusLabel.text = "Unsupported"
        case .unauthorized:
            bleStatusLabel.text = "Unauthorized"
        case .unknown:
            bleStatusLabel.text = "Unknown"
        case .resetting:
            bleStatusLabel.text = "Resetting"
        }
        
        print("Bluetooth status: " + bleStatusLabel.text!)
    }


    @IBAction func startscanButton(_ sender: UIButton) {
        // Start scanning for peripherals
        //centralManager.scanForPeripherals(withServices: nil, options: nil)
        centralManager.scanForPeripherals(withServices: [self.ServiceUUID], options: nil)
    }
    
    // Peripherals discovered delegate function
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        peripheralLabel.text = peripheral.name
        print("Found peripheral \(peripheral.name)")
        
        // Stop the scanning
        centralManager.stopScan()
        print("Stopped scanning for peripherals")
        
        // Connect to the peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        periconnectLabel.text = "Connected to \(peripheral.name)"
        print("Connected to \(peripheral.name)")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        periconnectLabel.text = "Could not connect"
        print("Failed to connect to \(peripheral.name)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            servicesLabel.text = "Failed to discover services" + error!.localizedDescription
            
            print("Failed to discover services " + error!.localizedDescription)
            return
        }
        
        let services = peripheral.services
        servicesLabel.text = "\(services)"
        print("Services available: \(services)")
        
        for service in services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            bleStatusLabel.text = "Failed to discover characteristics" + error!.localizedDescription
            
            print("Failed to discover characterists " + error!.localizedDescription)
            return
        }
        
        bleStatusLabel.text = "Characteristics discovered"
        print("Characteristics available: \(service.characteristics)")
    }
}

