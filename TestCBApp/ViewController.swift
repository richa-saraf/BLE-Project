//
//  ViewController.swift
//  TestCBApp
//
//  Created by Richa Saraf on 3/24/17.
//  Copyright © 2017 Richa Saraf. All rights reserved.
//

import UIKit
import CoreBluetooth

struct DisplayPeripheral {
    var peripheral: CBPeripheral?
    var lastRSSI: NSNumber?
    var localName: String?
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {

    @IBOutlet weak var bleStatusLabel: UILabel!
    
    @IBOutlet weak var peripheralLabel: UILabel!
    
    @IBOutlet weak var periconnectLabel: UILabel!
  
    @IBOutlet weak var servicesLabel: UILabel!
    
    
    // Variable declaration
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var peripheral_array: [DisplayPeripheral] = []
    
    var ServiceUUID : CBUUID!
    
    // let deviceUUID = UIDevice.current.identifierForVendor
    var CharacteristicUUID: CBUUID!
    
    var peripheralManager: CBPeripheralManager!
    var service: CBMutableService!
    var characteristic: CBMutableCharacteristic!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // UUID conversions
        self.ServiceUUID = CBUUID(string: OL_Uuids.SERVICE_UUID)
        
        self.CharacteristicUUID = CBUUID(string: OL_Uuids.CHARACTERISTIC_UUID)
        
        //Initialize Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        
        // Initialize Peripheral Manager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
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
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        //centralManager.scanForPeripherals(withServices: [self.ServiceUUID], options: nil)
    }
    
    /*
    // Peripherals discovered delegate function
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        peripheralLabel.text = peripheral.name
        print("Found peripheral \(peripheral.name)")
        print("RSSI value: \(RSSI.decimalValue)")
        
        // Stop the scanning
        centralManager.stopScan()
        print("Stopped scanning for peripherals")
        
        // Connect to the peripheral
        centralManager.connect(peripheral, options: nil)
    }
 */
    
    // Peripherals discovered delegate function
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        for(index, foundPeripheral) in peripheral_array.enumerated() {
            if foundPeripheral.peripheral?.identifier == peripheral.identifier {
                peripheral_array[index].lastRSSI = RSSI
                return
            }
        }
        
        // let localName = advertisementData["kCBAdvDataLocalName"] as? String
        let localName = peripheral.name
        let displayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, localName: localName)
        peripheral_array.append(displayPeripheral)
        
        print("================================================")
        print(peripheral_array)
        print("================================================")
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        // Connect to the peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        periconnectLabel.text = "Connected to \(peripheral.name)"
        print("Connected to \(peripheral.name)")
        //peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        //periconnectLabel.text = "Could not connect"
        print("Failed to connect to \(peripheral.name)")
    }
    
    func stopScan() {
        centralManager.stopScan()
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
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOff:
            print("P: Powered OFF")
        case .poweredOn:
            print("P: Powered ON")
            self.addservice()
            self.advertise()
            // start advertising
        //peripheralManager.startAdvertising(:[self.service.uuid])
        case .unsupported:
            print("P: Unsupported")
        case .unauthorized:
            print("P: Unauthorized")
        case .unknown:
            print("P: Unknown")
        case .resetting:
            print("P: Resetting")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error != nil {
            print("P: Error adding the service " + error!.localizedDescription)
            return
        }
        
        print("P: Service has been added")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            print("P: Failed to start advertisement " + error!.localizedDescription)
            return
        }
        
        print("P: Started advertising!")
    }
    
    func addservice() {
        self.service = CBMutableService(type: self.ServiceUUID, primary: true)
        
        self.characteristic = CBMutableCharacteristic(type: self.CharacteristicUUID, properties: CBCharacteristicProperties.read, value: nil, permissions: CBAttributePermissions.readable)
        
        self.service.characteristics = [self.characteristic]
        
        peripheralManager.add(self.service)
    }
    
    func advertise() {
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [self.service.uuid]])
    }

}

