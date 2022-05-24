//
//  ScanPreviewViewController.swift
//  InstaPDF-SDK-iOS-Example
//
//  Created by mmackh on 24.05.22.
//

import UIKit
import BaseComponents
import InstaPDFSDK

import QuickLook

class ScanPreviewViewController: UIViewController, UICollectionViewDelegate {
    var onWillAppear: (()->())?
    var onWillDissappear: (()->())?
    var onCreateDocument: ((_ documentFilePathURL: URL)->())?
    
    var didScrollToBottom: Bool = false
    
    lazy var componentRender: ComponentRender<InstaPDF.Scan> = {
        let componentRender: ComponentRender<InstaPDF.Scan> = .init(layout: .list(style: .insetGrouped, configuration: { listConfiguration in
            
        }))
        componentRender.collectionView.delegate = self
        return componentRender
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.color(.background, .secondarySystemBackground)
        
        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .close, { [unowned self] barButtonItem in
            self.dismiss(animated: true, completion: nil)
        })
        
        title = "InstaPDF SDK Demo"
        
        view.addSplitView { [unowned self] splitView in
            splitView.addSubview(self.componentRender, layoutType: .percentage, value: 100)
        }
        
        let trashDocument: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain) { [unowned self] barButtonItem in
            ScanController.shared.scans.forEach { scan in
                scan.delete()
            }
            ScanController.shared.scans.removeAll()
            self.reloadData()
        }
        trashDocument.tintColor = .systemRed
        
        let addPageBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "doc.badge.plus"), style: .plain) { [unowned self] barButtonItem in
            self.dismiss(animated: true, completion: nil)
        }
        addPageBarButtonItem.tintColor = .label
        
        let exportPDFBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain) { [unowned self] barButtonItem in
            
            InstaPDF.DocumentCreator.generatePDF(from: ScanController.shared.scans, settings: .default) { documentFilePathURL in
                
                ScanController.shared.scans.removeAll()
                
                self.dismiss(animated: true) {
                    self.onCreateDocument?(documentFilePathURL)
                }
            }
        }
        exportPDFBarButtonItem.tintColor = .label
        
        
        navigationController?.isToolbarHidden = false
        toolbarItems = [trashDocument, .flexibleSpace(), addPageBarButtonItem, .flexibleSpace(), exportPDFBarButtonItem]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
        
        onWillAppear?()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.componentRender.collectionView.scrollToItem(at: .init(row: ScanController.shared.scans.count - 1, section: 0), at: [], animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        onWillDissappear?()
    }
    
    func reloadData() {
        if ScanController.shared.scans.count == 0 {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        componentRender.updateSnapshot { builder in
            builder.animated = true
            
            builder.appendSection(using: ScanCell.self, items: ScanController.shared.scans)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? ScanCell)?.onRequestScanDeletion = { [unowned self] scan in
            ScanController.shared.scans.remove(scan)
            
            // deletes the imageFiles (scan + original), otherwise they'll remain on disk
            scan.delete()
            
            self.reloadData()
        }
    }
}

class ScanCell: UICollectionViewCell {
    let imageView: UIImageView = UIImageView().mode(.scaleAspectFit)
    
    var onRequestScanDeletion: ((InstaPDF.Scan)->())?
    
    var scan: InstaPDF.Scan? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        color(.background, .white)
        
        addSplitView { [unowned self] splitView in
            splitView.addSubview(self.imageView, layoutType: .percentage, value: 100)
        }
        
        addSplitView { [unowned self] splitView in
            splitView.addPadding(layoutType: .percentage, value: 100)
            
            splitView.addSplitView(configurationHandler: { splitView in
                splitView.direction = .horizontal
                
                splitView.color(.background, .systemBackground.alpha(0.7))
                
                splitView.addPadding(layoutType: .percentage, value: 50)
                
                splitView.addSubview(UIButton("Delete Page").tint(.systemRed).addAction(for: .touchUpInside, { button in
                    guard let scan = scan else { return }
                    self.onRequestScanDeletion?(scan)
                }), layoutType: .automatic)
                
                splitView.addPadding(layoutType: .percentage, value: 50)
                
            }, layoutType: .fixed, value: 54)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindObject(_ obj: AnyObject) {
        guard let scan = obj as? InstaPDF.Scan else { return }
        
        self.scan = scan
        
        DispatchQueue.global(qos: .userInteractive).async {
            let image = UIImage(contentsOfFile: scan.imageFilePath)
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        var size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        size.height = size.width * 1.4
        return size
    }
}
