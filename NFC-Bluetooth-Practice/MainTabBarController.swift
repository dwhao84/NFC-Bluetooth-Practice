//
//  MainTabBarController.swift
//  NFC-Bluetooth-Practice
//
//  Created by Dawei Hao on 2025/4/21.
//

import UIKit

// MARK: - TabBarController
class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設置藍牙頁面
        let bluetoothVC = BluetoothViewController()
        bluetoothVC.tabBarItem = UITabBarItem(title: "藍牙", image: UIImage(systemName: "antenna.radiowaves.left.and.right"), tag: 0)
        
        // 設置NFC頁面
        let nfcVC = NFCReaderViewController()
        nfcVC.tabBarItem = UITabBarItem(title: "NFC", image: UIImage(systemName: "radiowaves.left"), tag: 1)
        
        // 設置TabBar控制器的視圖控制器
        let controllers = [bluetoothVC, nfcVC].map { UINavigationController(rootViewController: $0) }
        self.viewControllers = controllers
        
        // 設置TabBar外觀
        UITabBar.appearance().tintColor = .systemBlue
    }
}
