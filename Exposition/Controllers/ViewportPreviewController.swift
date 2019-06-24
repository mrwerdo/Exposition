//
//  ViewportPreviewController.swift
//  Exposition
//
//  Created by Andrew Thompson on 14/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Cocoa

class ViewportPreviewController: ViewportController {
    @IBOutlet weak var box: NSBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overlay.removeFromSuperview()
    }
    
    @objc func changeParameters(notification: Notification) {
        if let params = notification.userInfo?["parameters"] as? ViewController.Parameters {
            self.viewport.zoom = params.zoom
            self.viewport.origin = params.origin
            self.viewport.parameters = params.parameters
        }
    }
    
    override func setIndex(_ i: Int) {
        super.setIndex(i)
        self.imageView?.image = viewport.snapshot()
    }
    
    override var isSelected: Bool {
        didSet {
            box.borderType = isSelected ? .grooveBorder : .noBorder
        }
    }
}
