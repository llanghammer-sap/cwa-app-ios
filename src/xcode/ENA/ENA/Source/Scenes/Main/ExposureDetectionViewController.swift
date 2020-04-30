//
//  ExposureDetectionViewController.swift
//  ENA
//
//  Created by Bormeth, Marc on 30.04.20.
//  Copyright © 2020 SAP SE. All rights reserved.
//

import UIKit

class ExposureDetectionViewController: UIViewController {
    
    @IBOutlet weak var contactTitleLabel: UILabel!
    @IBOutlet weak var lastContactLabel: UILabel!

    @IBOutlet weak var lastSyncLabel: UILabel!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var nextSyncLabel: UILabel!
    
    @IBOutlet weak var infoTitleLabel: UILabel!
    @IBOutlet weak var infoTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contactTitleLabel.text = .lastContactTitle
        lastContactLabel.text = formatLastContact()
        
        lastSyncLabel.text = formatLastSync()
        syncButton.setTitle(.synchronize, for: [])
        nextSyncLabel.text = formatNextSync()
        
        infoTitleLabel.text = .info
        infoTextView.text = .infoText
    }
    

    private func formatLastContact() -> String {
        return "Vor 3 Tagen"
    }
    
    private func formatLastSync() -> String {
        var str: String = .lastSync
        str = str.replacingOccurrences(of: "$", with: String(4))
        return str
    }
    
    private func formatNextSync() -> String {
        return .nextSync
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

fileprivate extension String {
    static let today = NSLocalizedString("today", comment: "")
    static let yesterday = NSLocalizedString("yesterday", comment: "")
    static let hour = NSLocalizedString("hour", comment: "")
    static let hours = NSLocalizedString("hours", comment: "")
    
    static let lastContactTitle = NSLocalizedString("ExposureDetection_lastContactTitle", comment: "")
    static let lastContactTextDays = NSLocalizedString("ExposureDetection_lastContactText", comment: "")
    
    static let lastSync = NSLocalizedString("ExposureDetection_lastSync", comment: "")
    static let synchronize = NSLocalizedString("ExposureDetection_synchronize", comment: "")
    static let nextSync = NSLocalizedString("ExposureDetection_nextSync", comment: "")
    
    static let info = NSLocalizedString("ExposureDetection_info", comment: "")
    static let infoText = NSLocalizedString("ExposureDetection_infoText", comment: "")
    
}
