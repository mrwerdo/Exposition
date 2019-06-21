//
//  ViewController.swift
//  Exposition
//
//  Created by Andrew Thompson on 5/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Cocoa
import MetalKit

extension NSEvent {
    func locationIn(mtkView: MTKView) -> CGPoint {
        return mtkView.convert(locationInWindow, from: nil)
    }
}

extension NSResponder {
    func printResponderChain(_ nextResponder: NSResponder? = nil) {
        if nextResponder == nil {
            printResponderChain(self)
            return
        } else {
            print(nextResponder!)
        }
        
        if let nextResponder = nextResponder!.nextResponder {
            printResponderChain(nextResponder)
        }
    }
}

class ViewController: NSViewController, ParameterDelegate {
    var shaderIndex: Int = 0 {
        didSet {
            viewport.shader = shader
        }
    }
    var shader: Shader? {
        if let shaders = AppDelegate.shared.metal?.shaders {
            return shaders[shaderIndex % shaders.count]
        }
        return nil
    }
    
    private let minimumZoom: CGFloat = 0
    
    func update(position: CGPoint, zoom: CGFloat, origin: CGPoint) {
        
        func screenToComplex(point: CGPoint) -> CGPoint {
            let size = viewport?.drawableSize ?? .zero
            let scale = max(zoom/size.width, zoom/size.height)
            return CGPoint(x: (point.x - size.width/2) * scale,
                           y: (point.y - size.height/2) * scale)
        }
        
        viewport.cursorPosition = position
        viewport.origin = origin
        viewport.zoom = max(zoom, minimumZoom)

        let complexPoint = screenToComplex(point: position)
        coordinates.stringValue = String(format: "%.4f, %.4f",
                                         complexPoint.x,
                                         complexPoint.y)
        touchBarCursorLabel?.stringValue = coordinates.stringValue
        
        slider?.doubleValue = Double(viewport.zoom)
    }
    
    var shouldShowCursor: Bool {
        return UserDefaults.standard.bool(forKey: "shouldShowCursor")
    }

    @IBOutlet weak var overlay: ViewportOverlay!
    @IBOutlet weak var coordinates: NSTextField!
    @IBOutlet weak var viewport: Viewport!
    @IBOutlet weak var containerView: NSView!
    
    var slider: NSSlider?
    var touchBarCursorLabel: NSTextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = AppDelegate.shared.metal?.device else {
            return
        }
        viewport.device = device
        viewport.shader = shader
        
        overlay.delegate = self
    }

    override func viewDidAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(visabilityChanged), name: NSWindow.didChangeOcclusionStateNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(selectionDidChange(_:)), name: NSNotification.Name("CollectionViewDidSelectIndex"), object: nil)
    }
    
    @objc func selectionDidChange(_ notification: Notification) {
        if let cv = notification.object as? PreviewViewController {
            shaderIndex = cv.previewList.selectionIndexes.first ?? 0
        }
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func visabilityChanged(_ notification: Notification) {
//        if let window = notification.object as? NSWindow {
//            viewport.isPaused = !window.isVisible || !window.occlusionState.contains(.visible)
//        }
    }
    
    @IBAction func shouldShowCursor(_ sender: Any?) {
        overlay.showCursor = shouldShowCursor
    }
    
    @IBAction func shouldShowSplitView(_ sender: Any?) {
        
    }
    
    @objc @IBAction func reset(_ sender: Any) {
        overlay.reset()
    }
    
    @objc @IBAction func startCapture(_ sender: Any) {
        MTLCaptureManager.shared().startCapture(device: viewport.device!)
    }
    
    @objc @IBAction func endCapture(_ sender: Any) {
        MTLCaptureManager.shared().stopCapture()
    }
    
    func timestamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: now)
        formatter.dateFormat = "h.mm.ss a"
        let time = formatter.string(from: now)
        return "\(date) at \(time)"
    }
    
    @objc @IBAction func saveDocument(_ sender: Any) {
        let url = URL(fileURLWithPath: "\(NSHomeDirectory())/Desktop/Capture \(timestamp()).tiff")
        let size = viewport?.drawableSize ?? .zero
        if let image = shader?.makeImage(size: size, cursor: overlay.cursorPosition, zoom: CGSize(width: overlay.zoom, height: overlay.zoom), origin: overlay.origin) {
            if let data = image.pngRepresentation {
                do {
                    try data.write(to: url)
                } catch {
                    NSAlert(error: error).runModal()
                }
            }
        }
    }
}

public extension NSImage {
    var pngRepresentation: Data? {
        if let data = tiffRepresentation {
            return NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:])
        }
        return nil
    }
}

extension ViewController: NSTouchBarDelegate {
    
    @objc func zoomChanged(_ sender: NSSliderTouchBarItem) {
        overlay.zoom = CGFloat(sender.slider.doubleValue)
    }
    
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

extension ViewController {
    func selectIndex(_ index: Int) {
        shaderIndex = index
    }
}

extension ViewController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        let height: CGFloat = 100
        if splitView.frame.height - proposedPosition > height {
            return proposedPosition
        } else if splitView.frame.height - proposedPosition <= 25 {
            return splitView.frame.height - 25
        }
        return splitView.frame.height - height
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == containerView
    }
}
