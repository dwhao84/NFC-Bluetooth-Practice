//
//  BluetoothViewController.swift
//  NFC-Bluetooth-Practice
//
//  Created by Dawei Hao on 2025/4/21.
//

import UIKit
import CoreBluetooth

// MARK: - CBUID 結構體
struct CBUUIDs {
    static let BLEService_UUID = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB") // 電池服務示例
    static let BLECharacteristic_UUID = CBUUID(string: "00002A19-0000-1000-8000-00805F9B34FB") // 電池水平特性示例
}

class BluetoothViewController: UIViewController {
    let serviceBtn: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "掃描藍牙設備"
        btn.configuration = config
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // 狀態標籤
    let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "準備就緒"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .white
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // 電池電量容器
    let batteryContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    // 電池電量標籤
    let batteryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "電池電量: 0%"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    // 電池電量進度條
    let batteryProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemGreen
        progressView.trackTintColor = .systemGray3
        return progressView
    }()
    
    var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var peripheralNames: [String] = []
    var connectedPeripheral: CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "藍牙掃描器"
        view.backgroundColor = .white
        setupUI()
        setupConstraints()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func setupUI() {
        view.addSubview(serviceBtn)
        view.addSubview(statusLabel)
        view.addSubview(batteryContainer)
        view.addSubview(tableView)
        
        // 添加電池容器的子視圖
        batteryContainer.addSubview(batteryLabel)
        batteryContainer.addSubview(batteryProgressView)
        
        addTargets()
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // 藍牙掃描按鈕
            serviceBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            serviceBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            serviceBtn.heightAnchor.constraint(equalToConstant: 44),
            
            // 狀態標籤
            statusLabel.topAnchor.constraint(equalTo: serviceBtn.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 電池容器約束
            batteryContainer.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            batteryContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            batteryContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            batteryContainer.heightAnchor.constraint(equalToConstant: 80),
            
            // 電池標籤約束
            batteryLabel.topAnchor.constraint(equalTo: batteryContainer.topAnchor, constant: 16),
            batteryLabel.leadingAnchor.constraint(equalTo: batteryContainer.leadingAnchor, constant: 16),
            batteryLabel.trailingAnchor.constraint(equalTo: batteryContainer.trailingAnchor, constant: -16),
            
            // 電池進度條約束
            batteryProgressView.topAnchor.constraint(equalTo: batteryLabel.bottomAnchor, constant: 12),
            batteryProgressView.leadingAnchor.constraint(equalTo: batteryContainer.leadingAnchor, constant: 16),
            batteryProgressView.trailingAnchor.constraint(equalTo: batteryContainer.trailingAnchor, constant: -16),
            batteryProgressView.heightAnchor.constraint(equalToConstant: 10),
            
            // 調整表格視圖的位置，讓它在電池容器下方
            tableView.topAnchor.constraint(equalTo: batteryContainer.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func addTargets() {
        serviceBtn.addTarget(self, action: #selector(scanPeripherals), for: .touchUpInside)
    }
    
    @objc func scanPeripherals() {
        peripherals.removeAll()
        peripheralNames.removeAll()
        tableView.reloadData()
        
        // 重置連接狀態和電池顯示
        batteryContainer.isHidden = true
        batteryProgressView.progress = 0
        batteryLabel.text = "電池電量: 0%"
        
        // 更新狀態
        statusLabel.text = "準備掃描藍牙設備..."
        
        // 檢查藍牙狀態
        if centralManager.state == .poweredOn {
            // 使用服務UUID掃描，或掃描所有設備
            // centralManager.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
            centralManager.scanForPeripherals(withServices: nil)
            
            // 5秒後停止掃描以節省電量
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.centralManager.stopScan()
                if self.peripherals.isEmpty {
                    self.serviceBtn.configuration?.title = "掃描藍牙設備"
                    self.statusLabel.text = "沒有找到藍牙設備"
                    
                    // 如果沒有找到設備，顯示提示
                    let alert = UIAlertController(title: "沒有找到設備", message: "請確保藍牙設備已開啟並在範圍內", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "確定", style: .default))
                    self.present(alert, animated: true)
                } else {
                    self.statusLabel.text = "找到 \(self.peripherals.count) 個藍牙設備"
                }
            }
            
            print("掃描開始...")
            statusLabel.text = "正在掃描藍牙設備..."
            serviceBtn.configuration?.title = "正在掃描..."
        } else {
            statusLabel.text = "藍牙未開啟"
            let alert = UIAlertController(title: "藍牙未開啟", message: "請開啟藍牙後再試", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default))
            present(alert, animated: true)
        }
    }
    
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    // 更新電池電量顯示
    func updateBatteryLevel(_ level: Int) {
        DispatchQueue.main.async {
            // 顯示電池容器
            self.batteryContainer.isHidden = false
            
            // 更新電池標籤
            self.batteryLabel.text = "電池電量: \(level)%"
            
            // 更新進度條
            let progress = Float(level) / 100.0
            self.batteryProgressView.progress = progress
            
            // 根據電量調整進度條顏色
            if level <= 20 {
                self.batteryProgressView.progressTintColor = .systemRed
            } else if level <= 50 {
                self.batteryProgressView.progressTintColor = .systemOrange
            } else {
                self.batteryProgressView.progressTintColor = .systemGreen
            }
        }
    }
}

// MARK: - BluetoothViewController TableView Extensions
extension BluetoothViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let peripheral = peripherals[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = peripheral.name ?? "未知設備"
        content.secondaryText = peripheral.identifier.uuidString
        
        content.textProperties.color = .black
        content.secondaryTextProperties.color = .darkGray
        
        cell.contentConfiguration = content
        cell.backgroundColor = .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let peripheral = peripherals[indexPath.row]
        connectToPeripheral(peripheral)
    }
}

// MARK: - BluetoothViewController CBCentralManager Extensions
extension BluetoothViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
            statusLabel.text = "藍牙狀態: 未知"
        case .resetting:
            print("central.state is .resetting")
            statusLabel.text = "藍牙狀態: 重設中"
        case .unsupported:
            print("central.state is .unsupported")
            statusLabel.text = "藍牙狀態: 不支持"
        case .unauthorized:
            print("central.state is .unauthorized")
            statusLabel.text = "藍牙狀態: 未授權"
        case .poweredOff:
            print("central.state is .poweredOff")
            statusLabel.text = "藍牙狀態: 已關閉"
        case .poweredOn:
            print("central.state is .poweredOn")
            statusLabel.text = "藍牙狀態: 已開啟"
            // 藍牙已開啟，可以開始掃描
            serviceBtn.isEnabled = true
        @unknown default:
            print("central state is unknown")
            statusLabel.text = "藍牙狀態: 未知狀態"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // 避免重複添加設備
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
            peripheralNames.append(peripheral.name ?? "未知設備")
            tableView.reloadData()
            statusLabel.text = "找到設備: \(peripheral.name ?? "未知設備")"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("已連接到 \(peripheral.name ?? "未知設備")")
        
        // 更新狀態
        statusLabel.text = "已連接到: \(peripheral.name ?? "未知設備")"
        
        // 更新按鈕文字
        serviceBtn.configuration?.title = "已連接"
        
        // 連接後，探索設備的服務
        peripheral.discoverServices(nil) // 或指定服務 [CBUUIDs.BLEService_UUID]
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("連接失敗: \(error?.localizedDescription ?? "未知錯誤")")
        serviceBtn.configuration?.title = "掃描藍牙設備"
        statusLabel.text = "連接失敗: \(error?.localizedDescription ?? "未知錯誤")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("斷開連接: \(peripheral.name ?? "未知設備")")
        serviceBtn.configuration?.title = "掃描藍牙設備"
        statusLabel.text = "已斷開連接: \(peripheral.name ?? "未知設備")"
        connectedPeripheral = nil
        
        // 隱藏電池顯示
        batteryContainer.isHidden = true
    }
}

// MARK: - BluetoothViewController CBPeripheral Extensions
extension BluetoothViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("服務探索失敗: \(error.localizedDescription)")
            statusLabel.text = "服務探索失敗"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("發現服務: \(service)")
            statusLabel.text = "發現服務: \(service.uuid)"
            // 探索每個服務中的特性
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("特性探索失敗: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("發現特性: \(characteristic)")
            
            // 如果需要讀取特性值
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            // 如果需要訂閱通知
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("讀取特性值失敗: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        // 處理收到的數據
        print("收到數據: \(data)")
        
        // 示例：如果是電池電量特性
        if characteristic.uuid == CBUUIDs.BLECharacteristic_UUID {
            if let byteData = data.first {
                let batteryLevel = Int(byteData)
                print("電池電量: \(batteryLevel)%")
                statusLabel.text = "電池電量更新: \(batteryLevel)%"
                
                // 更新 UI 顯示電池電量
                updateBatteryLevel(batteryLevel)
            }
        }
    }
}
