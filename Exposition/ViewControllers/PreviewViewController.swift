//
//  PreviewViewController.swift
//  Exposition
//
//  Created by Andrew Thompson on 14/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Cocoa

class PreviewViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return AppDelegate.shared.metal?.shaders.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("cv"), for: indexPath)
        if let v = item as? FractalPreview {
            v.setIndex(indexPath.item)
        }
        return item
    }
    
    @IBOutlet weak var previewList: NSCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        previewList.register(FractalPreview.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("cv"))
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let n = Notification(name: Notification.Name("CollectionViewDidSelectIndex"), object: self, userInfo: nil)
        NotificationCenter.default.post(n)
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        if let vfl = collectionViewLayout as? NSCollectionViewFlowLayout {
            let dynamicLength = collectionView.frame.height - (vfl.sectionInset.top + vfl.sectionInset.bottom + vfl.headerReferenceSize.height + vfl.footerReferenceSize.height)
            let length = max(dynamicLength, 60)
            return NSSize(width: length, height: length)
        } else {
            let l = 60 // todo: layout items properly
            // they should be centered and should occupy their surrounding space
            return NSSize(width: l, height: l)
        }
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        previewList.collectionViewLayout?.invalidateLayout()
    }
}
