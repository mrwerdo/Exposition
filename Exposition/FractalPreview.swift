//
//  FractalPreview.swift
//  Exposition
//
//  Created by Andrew Thompson on 14/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Cocoa

class FractalPreview: NSCollectionViewItem {
    @IBOutlet weak var image: NSImageView?
    @IBOutlet weak var box: NSBox!
    
    func setIndex(_ i: Int) {
        image?.image = AppDelegate.shared.metal?.shaders[i].image
        box.borderType = isSelected ? .grooveBorder : .noBorder
    }
    
    override var isSelected: Bool {
        didSet {
            box.borderType = isSelected ? .grooveBorder : .noBorder
        }
    }
}
