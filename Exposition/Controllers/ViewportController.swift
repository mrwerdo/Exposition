//
//  ViewportController.swift
//  Exposition
//
//  Created by Andrew Thompson on 23/6/19.
//  Copyright © 2019 Andrew Thompson. All rights reserved.
//

import Cocoa
import MetalKit

class ViewportController: NSCollectionViewItem {

    static let UserInterfaceId = NSUserInterfaceItemIdentifier("ViewportControllerCollectionViewCell")

    var slider: NSSlider?
    var touchBarCursorLabel: NSTextField?
    
    @IBOutlet weak var overlay: ViewportOverlay!
    @IBOutlet weak var viewport: Viewport!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = AppDelegate.shared.metal?.device else {
            return
        }
     
        viewport.device = device
    }
    
    func setShader(_ shader: Shader?) {
        viewport.shader = shader
    }

    @objc func zoomChanged(_ sender: NSSliderTouchBarItem) {
        
    }
    
    func setIndex(_ i: Int) {
        viewport.shader = AppDelegate.shared.metal?.shaders[i]
    }
}

extension ViewportController: NSTouchBarDelegate {
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .expositionParameters
        touchBar.defaultItemIdentifiers = [.zoomScrubber, .flexibleSpace, .coordinatesLabel]
        touchBar.customizationAllowedItemIdentifiers = [.coordinatesLabel]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.coordinatesLabel:
            let cvi = NSCustomTouchBarItem(identifier: .coordinatesLabel)
            cvi.view = NSTextField(labelWithString: "(x, y)")
            touchBarCursorLabel = cvi.view as? NSTextField
            return cvi
        case NSTouchBarItem.Identifier.zoomScrubber:
            let slider = NSSliderTouchBarItem(identifier: .zoomScrubber)
            slider.label = "zoom"
            slider.action = #selector(zoomChanged(_:))
            slider.target = self
            slider.slider.minValue = 0.2
            slider.slider.maxValue = 5
            self.slider = slider.slider
            return slider
        default: return nil
        }
    }
}

extension NSTouchBar.CustomizationIdentifier {
    static let expositionParameters = "expositionParameters"
}

extension NSTouchBarItem.Identifier {
    static let coordinatesLabel = NSTouchBarItem.Identifier(rawValue: "coordinatesLabel")
    static let zoomScrubber = NSTouchBarItem.Identifier(rawValue: "zoomScrubber")
}
