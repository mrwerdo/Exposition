//
//  ViewController.swift
//  Exposition
//
//  Created by Andrew Thompson on 5/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Cocoa
import MetalKit

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

class ViewController: NSViewController, ParameterDelegate, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    var parameters: [String] = ["Cursor Position 1", "Cursor Position 2"]
    @IBOutlet weak var viewportCollectionView: NSCollectionView!

    var shouldShowCursor: Bool {
        return UserDefaults.standard.bool(forKey: "shouldShowCursor")
    }

    @IBOutlet weak var containerView: NSView!
    
    var slider: NSSlider?
    var touchBarCursorLabel: NSTextField?
    var viewportControllers: [ViewportController] {
        return viewportCollectionView.visibleItems().compactMap { $0 as? ViewportController }
    }
    var parameterValues: [CGPoint] = [.zero, .zero]
    
    func f2() -> [CGPoint] {
        let x = Complex(parameterValues[0])
        let y = Complex(parameterValues[1])
        
        return [2 * (y + x), 2 * x].map { CGPoint(x: $0.real, y: $0.imaginary) }
    }
    
    func f1() -> [CGPoint] {
        let x = Complex(parameterValues[0])
        let y = Complex(parameterValues[1])
        
        return [2 * x * y + y * y, x * x + 2 * x * y].map { CGPoint(x: $0.real, y: $0.imaginary) }
    }
    
    func f0() -> [CGPoint] {
        return parameterValues
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let id = ViewportController.UserInterfaceId
        viewportCollectionView.register(ViewportController.self, forItemWithIdentifier: id)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(selectionDidChange(notification:)),
                                               name: PreviewViewController.SelectionDidChange,
                                               object: nil)
        
        
    }
    
    override func viewDidAppear() {
        if let shaders = AppDelegate.shared.metal?.shaders {
            setShader(shaders[0 % shaders.count])
        }
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func selectionDidChange(notification: Notification) {
        guard let shaders = AppDelegate.shared.metal?.shaders else {
            return
        }
        
        if let sender = notification.object as? PreviewViewController {
            let index = sender.previewList.selectionIndexes.first ?? 0
            setShader(shaders[index % shaders.count])
        }
    }
    
    func setShader(_ shader: Shader) {
        viewportControllers.forEach {
            $0.setShader(shader)
        }
    }
    
    @objc @IBAction func reset(_ sender: Any) {
        viewportControllers.forEach {
            $0.overlay.reset()
        }
    }
    
    @IBAction func shouldShowCursor(_ sender: Any?) {
        viewportControllers.forEach {
            $0.overlay.showCursor = shouldShowCursor
        }
    }
    
    @IBAction func shouldShowSplitView(_ sender: Any?) {
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return parameters.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let id = ViewportController.UserInterfaceId
        let item = collectionView.makeItem(withIdentifier: id, for: indexPath)
        
        if let controller = item as? ViewportController {
            controller.overlay.delegate = self
            controller.overlay.name = parameters[indexPath.last ?? 0]
        }
        
        return item
    }
    
    static let ParametersChanged = Notification.Name("ViewControllerParametersChange")
    
    struct Parameters {
        var zoom: CGFloat
        var origin: CGPoint
        var parameters: [CGPoint]
    }
    
    func update(parameter: String, position: CGPoint, zoom: CGFloat, origin: CGPoint) {
        switch parameter {
        case parameters[0]:
            parameterValues[0] = position
        case parameters[1]:
            parameterValues[1] = position
        default:
            break
        }
        
        for controller in viewportControllers {
            if let viewport = controller.viewport {
                switch controller.overlay.name {
                case parameters[0]:
                    viewport.parameters = f0()
                case parameters[1]:
                    viewport.parameters = f2()
                default: break
                }
                
                viewport.zoom = zoom
                viewport.origin = origin
            }
        }
        
        let params = Parameters(zoom: zoom, origin: origin, parameters: f0())
        NotificationCenter.default.post(name: ViewController.ParametersChanged, object: nil, userInfo: ["parameters": params])
    }
    
    @objc @IBAction func startCapture(_ sender: Any) {
        if let device = AppDelegate.shared.metal?.device {
            MTLCaptureManager.shared().startCapture(device: device)
        }
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
//        let url = URL(fileURLWithPath: "\(NSHomeDirectory())/Desktop/Capture \(timestamp()).tiff")
//        if let image = viewport.snapshot() {
//            if let data = image.pngRepresentation {
//                do {
//                    try data.write(to: url)
//                } catch {
//                    NSAlert(error: error).runModal()
//                }
//            }
//        }
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
