import UIKit
import CoreNFC

// MARK: - NFCReaderViewController (NFC讀取頁面)
class NFCReaderViewController: UIViewController {
    
    // 表格視圖用於顯示讀取到的NFC訊息
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    let reuseIdentifier = "reuseIdentifier"
    var detectedMessages = [NFCNDEFMessage]()
    var session: NFCNDEFReaderSession?
    
    // NFC掃描按鈕
    let scanNFCButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "掃描NFC標籤"
        config.baseForegroundColor = .systemGreen
        config.cornerStyle = .capsule
        btn.configuration = config
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // NFC資訊標籤
    let nfcInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "請點擊按鈕開始掃描NFC標籤"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()
    
    // NFC掃描圖示
    let nfcImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        
        // 使用系統提供的NFC圖示
        if let nfcIcon = UIImage(systemName: "radiowaves.left") {
            imageView.image = nfcIcon
        }
        
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "NFC讀取"
        view.backgroundColor = .white
        
        setupUI()
        setupConstraints()
        
        // 設置表格視圖
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        nfcImageView.addSymbolEffect(.bounce, options: .repeat(.continuous))
    }
    
    func setupUI() {
        view.addSubview(nfcInfoLabel)
        view.addSubview(nfcImageView)
        view.addSubview(tableView)
        
        // 將掃描按鈕添加到導航欄
        let scanNFCBarButtonItem = UIBarButtonItem(customView: scanNFCButton)
        navigationItem.rightBarButtonItem = scanNFCBarButtonItem
        
        scanNFCButton.addTarget(self, action: #selector(scanNFCTapped), for: .touchUpInside)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // NFC圖示
            nfcImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nfcImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nfcImageView.widthAnchor.constraint(equalToConstant: 60),
            nfcImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // NFC資訊標籤
            nfcInfoLabel.topAnchor.constraint(equalTo: nfcImageView.bottomAnchor, constant: 10),
            nfcInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nfcInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 表格視圖
            tableView.topAnchor.constraint(equalTo: nfcInfoLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func scanNFCTapped() {
        print("=== scanNFCTapped ===")
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "不支援NFC掃描",
                message: "此設備不支援NFC標籤掃描或應用未獲得授權",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
            self.present(alertController, animated: true)
            return
        }
        
        // 確保之前的會話已結束
        if session != nil {
            session?.invalidate()
            session = nil
        }
        
        // 創建新會話
        session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        session?.alertMessage = "請將您的iPhone靠近NFC標籤以讀取內容"
        session?.begin()
    }
}

// MARK: - NFCReaderViewController TableView Extensions
extension NFCReaderViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detectedMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        let message = detectedMessages[indexPath.row]
        let unit = message.records.count == 1 ? " 條資料" : " 條資料"
        cell.textLabel?.text = "NFC標籤 #\(indexPath.row + 1): \(message.records.count)" + unit
        cell.textLabel?.textColor = .darkGray
        cell.backgroundColor = .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 顯示NFC標籤詳細資訊
        let message = detectedMessages[indexPath.row]
        var detailText = ""
        
        for (i, record) in message.records.enumerated() {
            detailText += "記錄 #\(i + 1):\n"
            
            // 嘗試解析不同類型的數據
            if let typeString = String(data: record.type, encoding: .utf8) {
                detailText += "類型: \(typeString)\n"
            }
            
            // 嘗試解析NDEF負載
            if record.typeNameFormat == .nfcWellKnown {
                if let payloadString = String(data: record.payload, encoding: .utf8) {
                    let cleanPayload = String(payloadString.dropFirst(3)) // 去除NDEF標頭
                    detailText += "內容: \(cleanPayload)\n"
                } else {
                    detailText += "內容: (二進制數據)\n"
                }
            } else {
                if let payloadString = String(data: record.payload, encoding: .utf8) {
                    detailText += "內容: \(payloadString)\n"
                } else {
                    detailText += "內容: (二進制數據)\n"
                }
            }
            
            detailText += "\n"
        }
        
        let alertController = UIAlertController(
            title: "NFC標籤詳細資訊",
            message: detailText,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "確定", style: .default))
        present(alertController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white // 或任何你想要的背景顏色
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = detectedMessages.isEmpty ? "尚未掃描到NFC標籤" : "已掃描到的NFC標籤"
        titleLabel.textColor = .systemBlue // 在這裡設置你想要的顏色
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium) // 字體大小和粗細
        
        headerView.addSubview(titleLabel)
        
        // 設置約束
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        return headerView
    }

    // 設置 header 的高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40 // 可以根據需要調整
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCReaderViewController: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // 檢查會話失效的原因
        if let readerError = error as? NFCReaderError {
            // 如果不是因為成功讀取或用戶取消而失效，則顯示警告
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(
                    title: "讀取工作階段已結束",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        // 要讀取新標籤，需要新的會話實例
        self.session = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            self.detectedMessages.append(contentsOf: messages)
            self.tableView.reloadData()
            self.nfcInfoLabel.text = "已掃描到 \(self.detectedMessages.count) 個NFC標籤"
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // 如果檢測到多個標籤，500毫秒後重新啟動輪詢
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "檢測到多個標籤，請移除所有標籤後重試。"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // 連接到找到的標籤並執行NDEF訊息讀取
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "無法連接到標籤。"
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if .notSupported == ndefStatus {
                    session.alertMessage = "標籤不符合NDEF規範"
                    session.invalidate()
                    return
                } else if nil != error {
                    session.alertMessage = "無法查詢標籤的NDEF狀態"
                    session.invalidate()
                    return
                }
                
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    var statusMessage: String
                    if nil != error || nil == message {
                        statusMessage = "無法從標籤讀取NDEF訊息"
                    } else {
                        statusMessage = "已找到NDEF訊息"
                        DispatchQueue.main.async {
                            // 處理檢測到的NFCNDEFMessage對象
                            self.detectedMessages.append(message!)
                            self.tableView.reloadData()
                            self.nfcInfoLabel.text = "已掃描到 \(self.detectedMessages.count) 個NFC標籤"
                        }
                    }
                    
                    session.alertMessage = statusMessage
                    session.invalidate()
                })
            })
        })
    }
    
    // 從用戶活動中添加消息（用於處理外部來源的NFC標籤）
    func addMessage(fromUserActivity message: NFCNDEFMessage) {
        DispatchQueue.main.async {
            self.detectedMessages.append(message)
            self.tableView.reloadData()
            self.nfcInfoLabel.text = "已掃描到 \(self.detectedMessages.count) 個NFC標籤"
        }
    }
}
