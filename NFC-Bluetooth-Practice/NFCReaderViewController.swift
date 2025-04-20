
import UIKit
import CoreNFC

// MARK: - NFCReaderViewController (NFC讀取頁面)
class NFCReaderViewController: UIViewController {
    
    // NFC掃描按鈕
    let scanNFCButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "掃描NFC標籤"
        config.baseBackgroundColor = .systemGreen
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
    }
    
    func setupUI() {
        view.addSubview(scanNFCButton)
        view.addSubview(nfcInfoLabel)
        view.addSubview(nfcImageView)
        
        scanNFCButton.addTarget(self, action: #selector(scanNFCTapped), for: .touchUpInside)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // NFC圖示
            nfcImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nfcImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            nfcImageView.widthAnchor.constraint(equalToConstant: 100),
            nfcImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // NFC資訊標籤
            nfcInfoLabel.topAnchor.constraint(equalTo: nfcImageView.bottomAnchor, constant: 20),
            nfcInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nfcInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // NFC掃描按鈕
            scanNFCButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanNFCButton.topAnchor.constraint(equalTo: nfcInfoLabel.bottomAnchor, constant: 40),
            scanNFCButton.widthAnchor.constraint(equalToConstant: 200),
            scanNFCButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func scanNFCTapped() {
        // 這裡只是UI演示，實際上沒有實現NFC掃描功能
        nfcInfoLabel.text = "NFC功能尚未實現。這只是一個UI演示。"
        
        // 顯示一個警告，告訴用戶這只是一個UI演示
        let alert = UIAlertController(
            title: "NFC功能演示",
            message: "這只是一個UI演示。實際的NFC掃描功能尚未實現。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
}
