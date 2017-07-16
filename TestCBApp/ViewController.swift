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
    
    var userName: String
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate,  UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var ScanTableView: UITableView!
    
    @IBOutlet weak var profile_pic: UIImageView!
        
    // Variable declaration
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var peripheral_array: [DisplayPeripheral] = []
    
    var ServiceUUID : CBUUID!
    
    // let deviceUUID = UIDevice.current.identifierForVendor
    var CharacteristicUUID: CBUUID!
    var ProfileCharacteristicUUID: CBUUID!
    
    var peripheralManager: CBPeripheralManager!
    var service: CBMutableService!
    var characteristic: CBMutableCharacteristic!
    var profileCharacteristic: CBMutableCharacteristic!

    var startscanTimer = Timer()
    var rssiTimer = Timer()
    
    var userNameBuffer: String!
    
    //var user_name: String = "This represents the SARAF family."
    var user_name: String = "Prisha Saraf"
    var EOM_msg: String = "EOM"
    
    var sendingEOM = false
    var sendingUserData = false
    
    var sendDataIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // UUID conversions
        self.ServiceUUID = CBUUID(string: OL_Uuids.OLink_SERVICE_UUID)
        
        self.CharacteristicUUID = CBUUID(string: OL_Uuids.UserName_CHARACTERISTIC_UUID)
        
        self.ProfileCharacteristicUUID = CBUUID(string: OL_Uuids.Profile_CHARACTERISTIC_UUID)
        
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
            startTimer()
            updateRSSI()
            // profile_pic.image = UIImage(named: "Prisha_profile.jpg")
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
    
    func startScan() {
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
        
        let localName = peripheral.name ?? "No Name"
        let displayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, localName: localName, userName: "")
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
        
        userNameBuffer = ""
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
        
        for _service in services! {
            if _service.uuid.isEqual(self.ServiceUUID) {
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
                //print("Will be reading user name value.")
                self.peripheral.setNotifyValue(true, for: _characteristic)
                //self.peripheral.readValue(for: _characteristic)
            }
            
            //if _characteristic.uuid.isEqual(self.ProfileCharacteristicUUID) {
              //  print("Will be reading profile image value.")
                //self.peripheral.readValue(for: _characteristic)
            //}
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Failed to read value " + error!.localizedDescription)
            return
        }
        
        // Check if the value field is not null
        guard let data = characteristic.value else {
            return
        }
        
        // Get the length of the data received.
        //let dataLength = data.count
        
        if characteristic.uuid == CharacteristicUUID {
            // Extract user name 
            //let datastring = NSString(data: data, encoding: String.Encoding.utf16.rawValue)
            guard let datastring = String(data: data, encoding: String.Encoding(rawValue:String.Encoding.utf8.rawValue)) else {
                return
            }
            
            print("Value Received: \(datastring)")
            
            if (datastring == "EOM") {
                print("Full message received: \(userNameBuffer)")
                self.peripheral.setNotifyValue(false, for: self.characteristic)
                for(index, foundPeripheral) in peripheral_array.enumerated() {
                    if foundPeripheral.peripheral.identifier == peripheral.identifier {
                        peripheral_array[index].userName = userNameBuffer
                        print(peripheral_array)
                        return
                    }
                }
            } else {
                userNameBuffer.append(datastring)
            }
            
        }
        
        //if characteristic.uuid == ProfileCharacteristicUUID {
            // Extract profile image here
          //  let dataimage = UIImage(data: data)
            //print("Total bytes received for image: \(dataLength)")
            //profile_pic.image = dataimage
        //}

        //centralManager.cancelPeripheralConnection(peripheral)
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
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("P: Received read request: \(request)")
    }
    
    // Function to send data
    func sendData(peripheral: CBPeripheralManager) {
        
        let val_str_encoded = user_name.data(using: .utf8)
        let eom_msg = EOM_msg.data(using: .utf8)
        
        // Firstly, check if we need to send eom message
        if (sendingEOM) {
            
            // send it
            let didSend = peripheral.updateValue(eom_msg!, for: self.characteristic, onSubscribedCentrals: nil)
            
            // Did it send?
            if (didSend) {
                
                // It did, so mark it as sent
                sendingEOM = false
                sendingUserData = false
            }
            
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return;
        }
        
        // We're not sending an EOM, so we're sending data
        
        // Is there any left to send?
        
        if sendDataIndex >= (val_str_encoded?.count)! {
            
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        
        var didSend = true
        var chunk:Data
        
        while (didSend) {
            
            sendingUserData = true
            
            // Make the next chunk
            
            // Work out how big it should be
            var amountToSend = min((val_str_encoded?.count)! - sendDataIndex, MTU)
            
            // Copy out the data we want
            chunk = (val_str_encoded?.subdata(in: sendDataIndex..<sendDataIndex+amountToSend))!
            
            // Send it
            didSend = peripheral.updateValue(chunk, for: self.characteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if (!didSend) {
                return;
            }
            
            // Update the index
            self.sendDataIndex += amountToSend
            
            // Was it the last one?p
            if sendDataIndex >= (val_str_encoded?.count)! {
                
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                sendingEOM = true
                
                // Send it
                let eomSent = peripheral.updateValue(eom_msg!, for: self.characteristic, onSubscribedCentrals: nil)
                
                if (eomSent) {
                    // It sent, we're all done
                    sendingEOM = false
                    sendingUserData = false
                }
                
                return;
            }
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("Ready to update subscribers")
        self.sendData(peripheral: peripheral)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Sending data")
        
        self.sendData(peripheral: peripheral)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Unsubscribed!")
    }
    
    func addservice() {
        
        // let val_str = "Hello, my name is Richa Saraf! I love this world. I want to check the send limit of the text and see till which point this message is received. I would be surprised if I can see this entire line at the receiver!"
        
        //if let image_to_send = UIImage(named: "Prisha_profile.jpg") {
          //  if let image_data:Data = UIImageJPEGRepresentation(image_to_send, 1.0) {
            //    self.profileCharacteristic = CBMutableCharacteristic(type: self.ProfileCharacteristicUUID, properties: CBCharacteristicProperties.read, value: image_data, permissions: CBAttributePermissions.readable)
            //} else {
              //  print("The compression failed.")
            //}
        //} else {
          //  print("Could not fetch picture from the asset library.")
        //}
    
        self.service = CBMutableService(type: self.ServiceUUID, primary: true)
        
        self.characteristic = CBMutableCharacteristic(type: self.CharacteristicUUID, properties: CBCharacteristicProperties.notify, value: nil, permissions: CBAttributePermissions.readable)
        
        //self.characteristic = CBMutableCharacteristic(type: self.CharacteristicUUID, properties: CBCharacteristicProperties.read, value: val_str.data(using: .utf16), permissions: CBAttributePermissions.readable)
        
        //self.profileCharacteristic = CBMutableCharacteristic(type: self.ProfileCharacteristicUUID, properties: CBCharacteristicProperties.read, value: default_image, permissions: CBAttributePermissions.readable)
        
        //self.service.characteristics = [self.characteristic, self.profileCharacteristic]
        
        self.service.characteristics = [self.characteristic]
        peripheralManager.add(self.service)
    }
    
    func advertise() {
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [self.service.uuid]])
    }

    // Start scanning for 5 seconds
    func startTimer() {
        startscanTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ViewController.stopTimer), userInfo: nil, repeats: true)
        //print("start scanning")
        //let d = Date()
        //let df = DateFormatter()
        //df.dateFormat = "H:m:ss"
        //print("\(df.string(from: d)) : start scanning")
        startScan()
    }
    
    func stopTimer() {
        //let d = Date()
        //let df = DateFormatter()
        //df.dateFormat = "H:m:ss"
        //print("\(df.string(from: d)) : invalidate")
        // Stop scanning for peripherals
        startscanTimer.invalidate()
        stopScan()
        //let d2 = Date()
        // Wait 10 seconds before scanning for peripherals
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
            //print("\(df.string(from: d2)) : wait")
            self.startTimer()
        })
    }
    
    func updateRSSI() {
        rssiTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(ViewController._updateRSSI), userInfo: nil, repeats: true)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if error != nil {
            print("Error " + error!.localizedDescription)
            // The peripheral may not be available. Remove from array.
            for(index, deletePerioheral) in peripheral_array.enumerated() {
                if deletePerioheral.peripheral.identifier == peripheral.identifier {
                    print("Removing " + peripheral_array[index].localName)
                    peripheral_array.remove(at: index)
                    return
                }
            }
        }
        
        for(index, foundperipheral) in peripheral_array.enumerated() {
            // Look for peripheral and update its RSSI.
            if foundperipheral.peripheral.identifier == peripheral.identifier {
                print("Refreshing " + peripheral_array[index].localName)
                peripheral_array[index].lastRSSI = RSSI
                return
            }
        }
    }
    
    func _updateRSSI() {
        for(index, foundPeripheral) in peripheral_array.enumerated() {
            if foundPeripheral.peripheral.state == CBPeripheralState.connected {
                foundPeripheral.peripheral.readRSSI()
            } else {
                print(foundPeripheral.localName + " status: \(foundPeripheral.peripheral.state.rawValue)")
                peripheral_array.remove(at: index)
            }
        }
        
        ScanTableView.reloadData()
    }
}

