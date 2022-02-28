//
//  BluetoothManager.swift
//  BLEDevice
//
//  Created by David on 2022/2/28.
//

import UIKit
import CoreBluetooth

protocol BluetoothManagerDelegate: AnyObject {
    // CBCentralManagerDelegate
    func bluetoothDidStartScan()
    func bluetoothWillConnectToPeripheral()
    func bluetoothDidDiscoverPeripheral(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber)
    func bluetoothDidConnectToPeripheral(peripheral: CBPeripheral)
    func bluetoothDidFailToConnectPeripheral(central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    func bluetoothDidDisconnectToPeripheral()
    
    // CBPeripheralDelegate
    func bluetoothDidDiscoverCharacteristics(peripheral: CBPeripheral, characteristic: CBCharacteristic)
    func bluetoothDidUpdateNotificationState(peripheral: CBPeripheral, characteristic: CBCharacteristic)
    func bluetoothDidUpdateValue(value: Data)
    func bluetoothDidWriteValueForCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic)
}

extension BluetoothManagerDelegate {
    // CBCentralManagerDelegate
    func bluetoothDidStartScan() {}
    func bluetoothWillConnectToPeripheral() {}
    func bluetoothDidDiscoverPeripheral(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {}
    func bluetoothDidConnectToPeripheral(peripheral: CBPeripheral) {}
    func bluetoothDidFailToConnectPeripheral(central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {}
    func bluetoothDidDisconnectToPeripheral() {}
    
    // CBPeripheralDelegate
    func bluetoothDidDiscoverCharacteristics(peripheral: CBPeripheral, characteristic: CBCharacteristic) {}
    func bluetoothDidUpdateNotificationState(peripheral: CBPeripheral, characteristic: CBCharacteristic) {}
    func bluetoothDidUpdateValue(value: Data) {}
    func bluetoothDidWriteValueForCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic) {}
}

class BluetoothManager: NSObject {
    static let shared = BluetoothManager()
    var bluetoothDevices = [CBPeripheral]()
    var serviceUUIDList = [CBUUID]()
    var characteristicUUIDList = [CBUUID]()
    weak var delegate: BluetoothManagerDelegate?
    
    private var centralManager: CBCentralManager!
    private var connectPeripheral: CBPeripheral!
    
    func startScan() {
        if self.centralManager == nil {
            let queue = DispatchQueue.global(qos: .utility)
            self.centralManager = CBCentralManager(delegate: self, queue: queue)
        }
        
        switch self.centralManager.state {
        case .resetting:       print("resetting")
        case .unsupported:     print("unsupported")
        case .unauthorized:    print("unauthorized")
        case .poweredOff:
            guard let url = URL(string:"Prefs:root=Bluetooth") else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        case .poweredOn:
            self.centralManager.scanForPeripherals(
                withServices: self.serviceUUIDList,
                options:[CBCentralManagerScanOptionAllowDuplicatesKey : false]
            )
            
            self.delegate?.bluetoothDidStartScan()
            
        default:
            break
        }
    }
    
    func stopScan() {
        if let central = self.centralManager { central.stopScan() }
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        self.delegate?.bluetoothWillConnectToPeripheral()
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func writeValue(data: Data, forCharacteristic: CBCharacteristic, type: CBCharacteristicWriteType) throws {
        guard self.connectPeripheral.state == .connected else { return }
        self.connectPeripheral.writeValue(data, for: forCharacteristic, type: type)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.startScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let name = peripheral.name, name != "" else { return }
        
        if !self.bluetoothDevices.contains(peripheral) {
            self.bluetoothDevices.append(peripheral)
        }
        
        self.delegate?.bluetoothDidDiscoverPeripheral(peripheral: peripheral,
                                                      advertisementData: advertisementData,
                                                      rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
        self.connectPeripheral = peripheral
        self.connectPeripheral.delegate = self
        self.delegate?.bluetoothDidConnectToPeripheral(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("fail to connect")
        self.delegate?.bluetoothDidFailToConnectPeripheral(central: central,
                                                           didFailToConnect: peripheral,
                                                           error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnect")
        self.bluetoothDevices.removeAll()
        self.connectPeripheral = nil
        self.centralManager = nil
        self.delegate?.bluetoothDidDisconnectToPeripheral()
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            print("ERROR: \((#file, #function))")
            print(error!.localizedDescription)
        }
        
        guard let peripherals = peripheral.services else { return }
        
        for service in peripherals {
            if self.serviceUUIDList.contains(service.uuid) {
                peripheral.discoverCharacteristics(self.characteristicUUIDList, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            print("ERROR: \((#file, #function))")
            print(error!.localizedDescription)
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if self.characteristicUUIDList.contains(characteristic.uuid) {
                self.delegate?.bluetoothDidDiscoverCharacteristics(peripheral: peripheral,
                                                                   characteristic: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("ERROR: \((#file, #function))")
            print(error!.localizedDescription)
        }
        
        self.delegate?.bluetoothDidUpdateNotificationState(peripheral: peripheral,
                                                           characteristic: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("ERROR: \((#file, #function))")
            print(error!.localizedDescription)
        }
        
        guard let value = characteristic.value else { return }
        self.delegate?.bluetoothDidUpdateValue(value: value)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("WRITE ERROR: \(error!.localizedDescription)")
        }
        
        self.delegate?.bluetoothDidWriteValueForCharacteristic(peripheral: peripheral,
                                                               characteristic: characteristic)
    }
}
