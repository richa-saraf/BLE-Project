//
//  PeripheralViewController.swift
//  TestCBApp
//
//  Created by Richa Saraf on 3/25/17.
//  Copyright © 2017 Richa Saraf. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController : UIViewController, CBPeripheralManagerDelegate {
    
    // Variable declarations
    let deviceUUID = UIDevice.current.identifierForVendor
    var ServiceUUID: CBUUID!
    var CharacteristicUUID: CBUUID!
    
    var peripheralManager: CBPeripheralManager!
    var service: CBMutableService!
    var characteristic: CBMutableCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ServiceUUID = CBUUID(string: OL_Uuids.OLink_SERVICE_UUID)
        self.CharacteristicUUID = CBUUID(string: OL_Uuids.UserName_CHARACTERISTIC_UUID)
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
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
