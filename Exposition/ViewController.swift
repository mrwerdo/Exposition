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
        return mtkView.convertToBacking(mtkView.convert(locationInWindow, from: nil))
    }
}

class MetalView: MTKView {
    
    var cursor: NSCursor = NSCursor.crosshair
    
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: cursor)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override var canBecomeKeyView: Bool {
        return true
    }
}

class ViewController: NSViewController, MTKViewDelegate {
    var shaderIndex: Int = 0
    var shader: Shader? {
        if let shaders = AppDelegate.shared.metal?.shaders {
            return shaders[shaderIndex % shaders.count]
        }
        return nil
    }

    var didPickUp: Bool = false
    
    var cursorPosition: CGPoint = .zero {
        didSet {
            let complexPoint = screenToComplex(point: cursorPosition)
            coordinates.stringValue = String(format: "%.4f, %.4f",
                                             complexPoint.x,
                                             complexPoint.y)
            touchBarCursorLabel?.stringValue = coordinates.stringValue
        }
    }
    
    var isMouseDown: Bool = false
    var origin: CGPoint = .zero
    var cursor: NSCursor!
    var keyPressed: [CGKeyCode : Bool] = [:]
    
    var shouldShowCursor: Bool {
        return UserDefaults.standard.bool(forKey: "shouldShowCursor")
    }
    
    let minimumZoom = CGSize(width: 0.2, height: 0.2)
    
    @objc var zoom: CGSize = CGSize(width: 3, height: 3) {
        didSet {
            zoom.width = max(minimumZoom.width, zoom.width)
            zoom.height = max(minimumZoom.height, zoom.height)
            slider?.doubleValue = Double(min(zoom.width, zoom.height))
        }
    }

    @IBOutlet weak var coordinates: NSTextField!
    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var cursorImage: NSImageView!
    @IBOutlet weak var containerView: NSView!
    
    var slider: NSSlider?
    var touchBarCursorLabel: NSTextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cursorImage.image = NSCursor.crosshair.image
        cursorImage.isHidden = shouldShowCursor
        
        mtkView.autoResizeDrawable = true
        mtkView.framebufferOnly = false
        mtkView.delegate = self
        mtkView.preferredFramesPerSecond = 30
        guard let device = AppDelegate.shared.metal?.device else {
            return
        }
        mtkView.device = device
        
     
    }
    
    func graph(object: NSResponder?) {
        if let o = object {
            print(o)
            graph(object: o.nextResponder)
        }
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
        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeOcclusionStateNotification, object: nil)
    }
    
    @objc func visabilityChanged(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            mtkView.isPaused = !window.isVisible || !window.occlusionState.contains(.visible)
        }
    }
    
    func draw(in view: MTKView) {
        cursorKeyBindingUpdate()
        shader?.initaliseBuffer(cursor: cursorPosition, zoom: zoom, origin: origin)
        shader?.draw(in: view)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let scale = CGSize(width: size.width / view.drawableSize.width, height: size.height / view.drawableSize.height)
        cursorPosition.x *= scale.width
        cursorPosition.y *= scale.height
        origin.x *= scale.width
        origin.y *= scale.height
        _ = shader?.checkThreadgroupSize(for: size)
    }
    
    override func keyDown(with event: NSEvent) {
        keyPressed[event.keyCode] = true
    }
    
    override func keyUp(with event: NSEvent) {
        keyPressed[event.keyCode] = false
    }
    
    func cursorKeyBindingUpdate() {
        let keys = keyPressed.filter { $0.value }
        for v in keys {
            let dx: CGFloat = 1
            let dy: CGFloat =  1
            print(v)
            switch v.key {
            case 0:
                cursorPosition.x -= dx
            case 2:
                cursorPosition.x += dx
            case 1:
                cursorPosition.y -= dy
            case 13:
                cursorPosition.y += dy
            default: break
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        mtkView.isPaused = false
        if event.modifierFlags.contains(.option) {
            didPickUp = true
            super.mouseDown(with: event)
        } else {
            cursorPosition = event.locationIn(mtkView: mtkView)
            cursorImage.isHidden = true
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if didPickUp {
            super.mouseDragged(with: event)
        } else {
            cursorPosition = event.locationIn(mtkView: mtkView)
            cursorImage.isHidden = true
        }
    }

    override func mouseUp(with event: NSEvent) {
        if didPickUp {
            super.mouseUp(with: event)
        } else {
            cursorPosition = event.locationIn(mtkView: mtkView)
            updateCursor()
        }
        didPickUp = false
    }

    func updateCursor() {
        let s = cursorImage.frame.size
        cursorImage.setFrameOrigin(
            CGPoint(x: cursorPosition.x/2 - s.width/2,
                    y: cursorPosition.y/2 - s.height/2)
        )
        if (shouldShowCursor) {
            cursorImage.isHidden = false
        }
    }

    @IBAction func shouldShowCursor(_ sender: Any?) {
        updateCursor()
        cursorImage.isHidden = shouldShowCursor
    }
    
    override func scrollWheel(with event: NSEvent) {
        origin = CGPoint(x: origin.x + event.scrollingDeltaX,
                         y: origin.y + event.scrollingDeltaY)
    }
    
    override func magnify(with event: NSEvent) {
        zoom.width *= 1 - event.magnification
        zoom.height *= 1 - event.magnification
    }
    
    override func smartMagnify(with event: NSEvent) {
        zoom.width *= 1.5
        zoom.height *= 1.5
    }
    
    @objc @IBAction func reset(_ sender: Any) {
        zoom = CGSize(width: 3,
                      height: 3)
        origin = .zero
        cursorPosition = .zero
        updateCursor()
    }
    
    @objc @IBAction func startCapture(_ sender: Any) {
        MTLCaptureManager.shared().startCapture(device: mtkView.device!)
    }
    
    @objc @IBAction func endCapture(_ sender: Any) {
        MTLCaptureManager.shared().stopCapture()
    }
    
    func screenToComplex(point: CGPoint) -> CGPoint {
        let size = mtkView?.drawableSize ?? .zero
        let scale = max(zoom.width/size.width, zoom.height/size.height)
        return CGPoint(x: (point.x - size.width/2) * scale,
                       y: (point.y - size.height/2) * scale)
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
        let size = mtkView?.drawableSize ?? .zero
        if let image = shader?.makeImage(size: size, cursor: cursorPosition, zoom: zoom, origin: origin) {
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
        let magnification = CGFloat(sender.slider.doubleValue)
        zoom.width = magnification
        zoom.height = magnification
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
