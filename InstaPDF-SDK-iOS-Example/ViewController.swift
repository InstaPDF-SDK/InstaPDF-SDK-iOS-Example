//
//  ViewController.swift
//  InstaPDF-SDK-iOS-Example
//
//  Created by mmackh on 24.05.22.
//

import UIKit

import InstaPDFSDK
import BaseComponents

class ScanController {
    static let shared: ScanController = .init()
    
    var scans: [InstaPDF.Scan] = []
}

class ViewController: UIViewController {
    lazy var scanView: InstaPDF.ScanView = {
        // Setup licensing first
        InstaPDF.License.demo()
        
        // Add ScanView as subview, configure UI components
        let scanView: InstaPDF.ScanView = .init(uiConfiguration: .hideTopActionBar)
        
        // Finish setting up device
        scanView.setupDevice()
        
        return scanView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Build UI
        view.addSplitView { [unowned self] splitView in
            
            // scan view takes up 100% of the remaining area
            splitView.addSubview(self.scanView, layoutType: .percentage, value: 100)
            
            // avoid slipping under the tab bar
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .bottom)
        }
        
        scanView.onCaptureStateChange = { captureState in }
        
        scanView.onCancelAddPageTap = { [unowned self] in
            self.showScanPreviewViewController()
        }
        
        scanView.didCapture = { [unowned self] scan in
            ScanController.shared.scans.append(scan)
            self.showScanPreviewViewController()
        }
    }
    
    func showScanPreviewViewController() {
        let scanPreviewVC = ScanPreviewViewController()
        
        // leave running in the background for faster scanning times, but disable autocrop
        scanView.softDisable = true
        scanPreviewVC.onCreateDocument = { [unowned self] documentFilePathURL in
            let activityVC = UIActivityViewController(activityItems: [documentFilePathURL], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { (activity, success, items, error)  in
                self.scanView.softDisable = false
            }
            self.scanView.softDisable = true
            self.present(activityVC, animated: true, completion: nil)
        }
        scanPreviewVC.onWillAppear = {
            self.scanView.softDisable = true
        }
        scanPreviewVC.onWillDissappear = {
            self.scanView.showCancelAddPage = ScanController.shared.scans.count > 0
            self.scanView.softDisable = false
        }
        
        self.present(scanPreviewVC.embedInNavigationController(), animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scanView.updateVideoOrientation()
        scanView.enableCapture = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        scanView.enableCapture = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

