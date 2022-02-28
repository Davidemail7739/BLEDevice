//
//  ViewController.swift
//  BLEDevice
//
//  Created by David on 2022/2/28.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    @IBOutlet weak var labelBattery: UILabel!
    @IBOutlet weak var btnConnect: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private var bluetoothManager = BluetoothManager.shared
    private weak var writeCharacteristic: CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnConnect.layer.cornerRadius = 10
        self.btnConnect.layer.borderWidth = 1
        self.bluetoothManager.delegate = self
    }

    @IBAction func search(_ sender: UIButton) {
        self.bluetoothManager.delegate = self
        self.bluetoothManager.startScan()
        self.tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.bluetoothManager.bluetoothDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceTableViewCell", for: indexPath) as! DeviceTableViewCell
        
        cell.bluetoothWithDevice(name: bluetoothManager.bluetoothDevices[indexPath.row].name ?? "")
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service = "1fee6acf-a826-4e37-9635-4d8a01642c5d"
        
        for peripheral in self.bluetoothManager.bluetoothDevices {
            guard peripheral.identifier.uuidString == service, !self.bluetoothManager.serviceUUIDList.contains(CBUUID(string: service)) else { continue }
            
            self.bluetoothManager.serviceUUIDList.append(contentsOf: [CBUUID(string: service)])
        }
    }
}

extension ViewController: BluetoothManagerDelegate {
    func bluetoothDidDiscoverPeripheral(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        
        print("bluetoothDidDiscoverPeripheral")
        
        self.bluetoothManager.stopScan()
        self.bluetoothManager.connectToPeripheral(peripheral: peripheral)
    }
    
    func bluetoothDidConnectToPeripheral(peripheral: CBPeripheral) {
        print("bluetoothDidConnectToPeripheral")
        
        let service = "1fee6acf-a826-4e37-9635-4d8a01642c5d"
        let characteristic = "7691b78a-9015-4367-9b95-fc631c412cc6"
        
        guard peripheral.identifier.uuidString == service, !self.bluetoothManager.characteristicUUIDList.contains(CBUUID(string: characteristic)) else { return }
        
        self.bluetoothManager.characteristicUUIDList.append(CBUUID(string: "7691b78a-9015-4367-9b95-fc631c412cc6"))
        
        peripheral.discoverServices(self.bluetoothManager.serviceUUIDList)
    }
    
    func bluetoothDidDiscoverCharacteristics(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        print("bluetoothDidDiscoverCharacteristics")
        
        self.writeCharacteristic = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    func bluetoothDidUpdateNotificationState(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        
        print("bluetoothDidUpdateNotificationState")
        
        self.labelBattery.text = "86%"
        
        // 正常狀況下這裡要write somthing(如下)，但因為無法得知要寫入什麼，所以就只能用假資料顯示，如果service uuid和Characteristic uuid都是正確的話，才會正常走到這一步驟
//        do {
//            try self.bluetoothManager.writeValue(
//                data: data,
//                forCharacteristic: self.writeCharacteristic,
//                type: .withoutResponse
//            )
//
//        } catch {
//            print("詢問電量-error: " + error.localizedDescription)
//        }
    }
}
