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
    @IBOutlet weak var nextViewControllerResponder: NSResponder?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        nextViewControllerResponder?.keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        nextViewControllerResponder?.keyUp(with: event)
    }
}

class ViewController: NSViewController, MTKViewDelegate, NSGestureRecognizerDelegate {
    
    class Shader {
        var function: MTLFunction
        var pipeline: MTLComputePipelineState
        private var threadgroupSize: ThreadgroupSizes? = nil
        
        init(function: MTLFunction, pipeline: MTLComputePipelineState) {
            self.function = function
            self.pipeline = pipeline
        }
        
        func threadgroupSize(_ drawableSize: CGSize) -> ThreadgroupSizes {
            if let t = threadgroupSize {
                return t
            }
            threadgroupSize = pipeline.threadgroupSizesForDrawableSize(drawableSize)
            return threadgroupSize!
        }
        
        static func shaderIncanation(library: MTLLibrary, use_escape_iteration: Bool) -> Shader {
            let v = MTLFunctionConstantValues()
            var value = use_escape_iteration
            v.setConstantValue(&value, type: .bool, index: 0)
            print(value)
            let function = try! library.makeFunction(name: "newtonShader", constantValues: v)
            let pipeline = try! library.device.makeComputePipelineState(function: function)
            function.label = function.name + "\(value)"
            return Shader(function: function, pipeline: pipeline)
        }
        
        static func makeShaders(library: MTLLibrary) -> [Shader] {
            return [
                shaderIncanation(library: library, use_escape_iteration: true),
                shaderIncanation(library: library, use_escape_iteration: false)
            ]
        }
    }
    
    var library: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    var buffer: MTLBuffer!
    var shaders: [Shader] = []
    var shaderIndex: Int = 0
    var shader: Shader {
        return shaders[shaderIndex]
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyUp(with event: NSEvent) {
        shaderIndex = (shaderIndex + 1) % 2
    }
    
    override func keyDown(with event: NSEvent) {
        
    }
    
    var didPickUp: Bool = false
    
    var cursorPosition: CGPoint = .zero {
        didSet {
            let complexPoint = screenToComplex(point: cursorPosition)
            coordinates.stringValue = String(format: "%.4f, %.4f",
                                             complexPoint.x,
                                             complexPoint.y)
        }
    }
    var isMouseDown: Bool = false
    var origin: CGPoint = .zero
    
    let minimumZoom = CGSize(width: 0.2, height: 0.2)
    
    var zoom: CGSize = CGSize(width: 3, height: 3) {
        didSet {
            zoom.width = max(minimumZoom.width, zoom.width)
            zoom.height = max(minimumZoom.height, zoom.height)
        }
    }

    @IBOutlet weak var coordinates: NSTextField!
    @IBOutlet weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mtkView.autoResizeDrawable = true
        mtkView.framebufferOnly = false
        mtkView.delegate = self
        mtkView.preferredFramesPerSecond = 30
        
        guard let device = MTLCopyAllDevices().sorted(by: {
            $0.recommendedMaxWorkingSetSize > $1.recommendedMaxWorkingSetSize
        }).first else {
            fatalError("no graphics card!")
        }
        mtkView.device = device
        
        commandQueue = device.makeCommandQueue()
        
        library = device.makeDefaultLibrary()
        buffer = device.makeBuffer(length: 6 * MemoryLayout<Float32>.size, options: [.cpuCacheModeWriteCombined])
        
        shaders = Shader.makeShaders(library: library)
        
        print(shaders.map { $0.function.label })
    }
    
    override func viewDidAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(visabilityChanged), name: NSWindow.didChangeOcclusionStateNotification, object: nil)
        self.becomeFirstResponder()
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeOcclusionStateNotification, object: nil)
    }
    
    @objc func visabilityChanged(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            mtkView.isPaused = !window.isVisible || !window.occlusionState.contains(.visible)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            didPickUp = true
            super.mouseDown(with: event)
        } else {
            cursorPosition = event.locationIn(mtkView: mtkView)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if didPickUp {
            super.mouseDragged(with: event)
        } else {
            cursorPosition = event.locationIn(mtkView: mtkView)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if didPickUp {
            super.mouseUp(with: event)
        } else {
            cursorPosition = event.locationIn(mtkView: mtkView)
        }
        didPickUp = false
    }

    func draw(in view: MTKView) {
        
        if shader.threadgroupSize(mtkView.drawableSize).hasZeroDimension {
            return
        }
        
        autoreleasepool {
            guard let drawable = mtkView.currentDrawable else {
                print("currentDrawable nil!")
                return
            }
            
            guard let buffer = commandQueue.makeCommandBuffer(),
                let encoder = buffer.makeComputeCommandEncoder()
            else {
                return print("buffer or encoder nil!")
            }
            
            encoder.setTexture(drawable.texture, index: 0)
            encoder.setComputePipelineState(shader.pipeline)
            encoder.setBuffer(self.buffer, offset: 0, index: 0)
            
            let buf = self.buffer.contents().bindMemory(to: Float32.self, capacity: 6)
            buf[0] = Float32(self.cursorPosition.x)
            buf[1] = Float32(self.cursorPosition.y)
            buf[2] = Float32(self.origin.x)
            buf[3] = Float32(self.origin.y)
            buf[4] = Float32(self.zoom.width)
            buf[5] = Float32(self.zoom.height)
            
            encoder.dispatchThreadgroups(shader.threadgroupSize(mtkView.drawableSize).threadgroupsPerGrid, threadsPerThreadgroup: shader.threadgroupSize(mtkView.drawableSize).threadsPerThreadgroup)
            encoder.endEncoding()
            
            buffer.present(drawable)
            buffer.commit()
            buffer.waitUntilCompleted()
        }
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let scale = CGSize(width: size.width / view.drawableSize.width, height: size.height / view.drawableSize.height)
        cursorPosition.x *= scale.width
        cursorPosition.y *= scale.height
        origin.x *= scale.width
        origin.y *= scale.height
        _ = shader.threadgroupSize(size)
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
}
