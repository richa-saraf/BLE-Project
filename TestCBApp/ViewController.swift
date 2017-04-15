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
    var peripheral: CBPeripheral
    var lastRSSI: NSNumber
    var localName: String
    //var profileImage: UIImage
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate,  UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var ScanTableView: UITableView!
    
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheral_array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanTableViewCell", for: indexPath)
        
        cell.textLabel?.text = peripheral_array[indexPath.row].localName
       cell.detailTextLabel?.text = String(describing: peripheral_array[indexPath.row].lastRSSI)
        return cell
    }
    
    // CentralManagerDelegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("Powered OFF")
        case .poweredOn:
            print("Powered ON")
        case .unsupported:
            print("Unsupported")
        case .unauthorized:
            print("Unauthorized")
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        }
    }


    @IBAction func startscanButton(_ sender: UIButton) {
        // Start scanning for peripherals
        centralManager.scanForPeripherals(withServices: [self.ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    // Peripherals discovered delegate function
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        for(index, foundPeripheral) in peripheral_array.enumerated() {
            if foundPeripheral.peripheral.identifier == peripheral.identifier {
                peripheral_array[index].lastRSSI = RSSI
                return
            }
        }
        
        let localName = peripheral.name
        let displayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, localName: localName!)
        peripheral_array.append(displayPeripheral)
        
        print("================================================")
        print(peripheral_array)
        print("================================================")
        self.peripheral = peripheral
        self.peripheral.delegate = self

        ScanTableView.reloadData()
        // Connect to the peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral.name != nil {
            print("Connected to \(peripheral.name!)")
        }
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name)")
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("Failed to discover services " + error!.localizedDescription)
            return
        }
        
        let services = peripheral.services
        // print("Services available: \(services)")
        
        for _service in services! {
            if _service.uuid.isEqual(self.ServiceUUID) {
                //print("Needed service found.")
                peripheral.discoverCharacteristics(nil, for: _service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            
            print("Failed to discover characterists " + error!.localizedDescription)
            return
        }
        
        let characteristics = service.characteristics
        
        for _characteristic in characteristics!{
            if _characteristic.uuid.isEqual(self.CharacteristicUUID) {
                self.peripheral.readValue(for: _characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Failed to read value " + error!.localizedDescription)
            return
        }
        
        guard let data = characteristic.value else {
            return
        }
        
        let datastring = NSString(data: data, encoding: String.Encoding.utf16.rawValue)
        if datastring != nil {
        print("Value: \(datastring!)")
        }
        
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to disconnect \(peripheral.name) " + error!.localizedDescription)
            return
        }
        
        if peripheral.name != nil {
            print("Disconnected from \(peripheral.name!)")
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOff:
            print("P: Powered OFF")
        case .poweredOn:
            print("P: Powered ON")
            self.addservice()
            self.advertise()
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("P: Received read request: \(request)")
    }
    
    func addservice() {
        
        let val_str = "Hello, World!"
        //let cString = val_str.cString(using: .utf8)! // null-terminated
        
        self.service = CBMutableService(type: self.ServiceUUID, primary: true)
        
        self.characteristic = CBMutableCharacteristic(type: self.CharacteristicUUID, properties: CBCharacteristicProperties.read, value: val_str.data(using: .utf16), permissions: CBAttributePermissions.readable)
        
        self.service.characteristics = [self.characteristic]
        
        peripheralManager.add(self.service)
    }
    
    func advertise() {
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [self.service.uuid]])
    }

}

