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

class ViewController: NSViewController, MTKViewDelegate {
    
    var threadgroupSize: ThreadgroupSizes!
    var library: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    var shader: MTLFunction!
    var pipeline: MTLComputePipelineState!
    var buffer: MTLBuffer!
    
    var cursorPosition: CGPoint = .zero
    var isMouseDown: Bool = false

    @IBOutlet weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mtkView.autoResizeDrawable = true
        mtkView.framebufferOnly = false
        mtkView.delegate = self
        mtkView.preferredFramesPerSecond = 30
        
        let devices = MTLCopyAllDevices().sorted {
            $0.recommendedMaxWorkingSetSize > $1.recommendedMaxWorkingSetSize
        }
        print(devices)
        let device = devices.first!
        print(device.recommendedMaxWorkingSetSize)
        mtkView.device = device
        
        commandQueue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        
        shader = library.makeFunction(name: "newtonShader");
        pipeline = try! device.makeComputePipelineState(function: shader)
        buffer = device.makeBuffer(length: 2 * MemoryLayout<Float32>.size, options: [.cpuCacheModeWriteCombined])
        
        threadgroupSize = pipeline.threadgroupSizesForDrawableSize(mtkView.drawableSize)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        cursorPosition = event.locationIn(mtkView: mtkView)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        cursorPosition = event.locationIn(mtkView: mtkView)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        if !event.modifierFlags.contains(.option) {
            cursorPosition = event.locationIn(mtkView: mtkView)
        }
    }

    func draw(in view: MTKView) {
        
        if threadgroupSize.hasZeroDimension {
            return
        }
        
        autoreleasepool {
            guard let drawable = mtkView.currentDrawable else {
                return
            }
            
            guard let buffer = commandQueue.makeCommandBuffer(),
                let encoder = buffer.makeComputeCommandEncoder()
            else {
                return
            }
            
            encoder.setTexture(drawable.texture, index: 0)
            encoder.setComputePipelineState(pipeline)
            encoder.setBuffer(self.buffer, offset: 0, index: 0)
            
            let buf = self.buffer.contents().bindMemory(to: Float32.self, capacity: 2)
            buf[0] = Float32(self.cursorPosition.x)
            buf[1] = Float32(self.cursorPosition.y)
            
            encoder.dispatchThreadgroups(threadgroupSize.threadgroupsPerGrid, threadsPerThreadgroup: threadgroupSize.threadsPerThreadgroup)
            encoder.endEncoding()
            
            buffer.present(drawable)
            buffer.commit()
            buffer.waitUntilCompleted()
        }
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        threadgroupSize = pipeline.threadgroupSizesForDrawableSize(size)
    }

}
