//
//  Shader.swift
//  Exposition
//
//  Created by Andrew Thompson on 14/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import MetalKit

extension String {
    func expand(macro: String, value: String) -> String {
        var output = ""
        enumerateLines { (line, stop) in
            if !line.trimmingCharacters(in: CharacterSet.whitespaces).starts(with: "#") {
                output += line.replacingOccurrences(of: macro, with: value) + "\n"
            } else {
                output += line + "\n"
            }
        }
        return output
    }
}

class Shader {
    var function: MTLFunction
    var pipeline: MTLComputePipelineState
    var buffer: MTLBuffer
    var image: NSImage {
        get {
            if _image == nil {
                _image = makeImage()
            }
            return _image!
        }
    }
    
    private var _image: NSImage? = nil
    private var threadgroupSize: ThreadgroupSizes? = nil
    private var size: CGSize? = nil
    
    init(function: MTLFunction, pipeline: MTLComputePipelineState, buffer: MTLBuffer) {
        self.function = function
        self.pipeline = pipeline
        self.buffer = buffer
    }
    
    func screenToComplex(point: CGPoint) -> Complex {
        // map point from car_size into com_size
        let carSize = CGSize(width: 1024, height: 1024)
        let comSize = CGSize(width: 4, height: 4)
        let comOri = CGPoint(x: -2, y: -2)
        
        return Complex(Double((point.x / carSize.width) * comSize.width + comOri.x),
                       Double((point.y / carSize.height) * comSize.height + comOri.y))
    }
    
    func initaliseBuffer(cursor: CGPoint, zoom: CGSize, origin: CGPoint) {
        let buf = buffer.contents().bindMemory(to: Float32.self, capacity: 6)
        buf[0] = Float32(cursor.x)
        buf[1] = Float32(cursor.y)
        buf[2] = Float32(origin.x)
        buf[3] = Float32(origin.y)
        buf[4] = Float32(zoom.width)
        buf[5] = Float32(zoom.height)
    }
    
    func makeImage(size: CGSize = CGSize(width: 512, height: 512)) -> NSImage? {
        
        guard let metal = AppDelegate.shared.metal else {
            fatalError()
        }
        
        initaliseBuffer(cursor: CGPoint(x: 384, y: 256),
                        zoom: CGSize(width: 1, height: 1),
                        origin: CGPoint(x: 0, y: 0)
        )
        
        let layer = CAMetalLayer()
        layer.allowsNextDrawableTimeout = false
        layer.displaySyncEnabled = false
        layer.presentsWithTransaction = false
        layer.frame.size = size
        layer.device = metal.device
        layer.framebufferOnly = false

        return autoreleasepool {
            let drawable = layer.nextDrawable()
            if !draw(commandQueue: metal.commandQueue, buffer: buffer, size: layer.drawableSize, currentDrawable: drawable) {
                return nil
            }
            
            let context = CIContext()
            guard let texture = drawable?.texture else {
                fatalError()
            }
            guard let cImg = CIImage(mtlTexture: texture, options: nil) else {
                fatalError()
            }
            guard let cgImg = context.createCGImage(cImg, from: cImg.extent) else {
                fatalError()
            }
            
            return NSImage(cgImage: cgImg, size: size)
        }
    }
    
    
    static func makeShaders(metal: MetalVars) -> [Shader] {
        let device = metal.device
        let url = Bundle.main.url(forResource: "Shaders", withExtension: "metal")!
        let source = try! String(contentsOf: url)

        func constants(_ val: Bool) -> MTLFunctionConstantValues {
            var value: Bool = val
            let values = MTLFunctionConstantValues()
            values.setConstantValue(&value, type: .bool, withName: "use_escape_iteration")
            return values
        }
        
        func function(equation: String, usingEscapeIteration: Bool)  throws -> MTLFunction {
            let preprocessedSource = source.expand(macro: "iterator", value: equation)
            let lib = try device.makeLibrary(source: preprocessedSource, options: nil)
            let f = try lib.makeFunction(name: "newtonShader", constantValues: constants(usingEscapeIteration))
            f.label  = "\(f.name), using escape iteration \(usingEscapeIteration)"
            return f
        }
        
        func shader(iterator: String, usingEscapeIteration: Bool) -> Shader? {
            guard let buffer = device.makeBuffer(length: 6 * MemoryLayout<Float32>.size, options: [.cpuCacheModeWriteCombined]) else {
                return nil
            }
            
            do {
                let d = try function(equation: iterator,
                                     usingEscapeIteration: usingEscapeIteration)
                let pipeline = try device.makeComputePipelineState(function: d)
                return Shader(function: d, pipeline: pipeline, buffer: buffer)
            } catch {
                print(error)
                fatalError()
            }
        }
        
        return [
            shader(iterator: "z - c * ((((z * z * z) - 1)/(3 * (z * z))))", usingEscapeIteration: true),
            shader(iterator: "z - c * (0.5 * z + 1/z)", usingEscapeIteration: false),
            shader(iterator: "z - c * cos(z)/(-sin(z))", usingEscapeIteration: true),
            shader(iterator: "z*z + c", usingEscapeIteration: true),
            shader(iterator: "z*z + Z", usingEscapeIteration: true),
            ].compactMap { $0 }
    }
    
    func checkThreadgroupSize(for drawableSize: CGSize) -> ThreadgroupSizes {
        if size != drawableSize || threadgroupSize == nil {
            threadgroupSize = pipeline.threadgroupSizesForDrawableSize(drawableSize)
            size = drawableSize
        }
        return threadgroupSize!
    }
    
    func draw(commandQueue: MTLCommandQueue, buffer buff: MTLBuffer, size drawableSize: CGSize, currentDrawable: @autoclosure () -> CAMetalDrawable?) -> Bool {
        
        if checkThreadgroupSize(for: drawableSize).hasZeroDimension {
            return false
        }

        return autoreleasepool {
            guard let drawable = currentDrawable() else {
                print(#file, #function, "currentDrawable nil!")
                return false
            }
            
            guard let buffer = commandQueue.makeCommandBuffer(),
                let encoder = buffer.makeComputeCommandEncoder()
                else {
                    print(#file, #function, "buffer or encoder nil!")
                    return false
            }
            
            encoder.setTexture(drawable.texture, index: 0)
            encoder.setComputePipelineState(pipeline)
            encoder.setBuffer(buff, offset: 0, index: 0)
            
            encoder.dispatchThreadgroups(threadgroupSize!.threadgroupsPerGrid,
                                         threadsPerThreadgroup: threadgroupSize!.threadsPerThreadgroup)
            encoder.endEncoding()
            
            buffer.commit()
            buffer.waitUntilCompleted()
            return true
        }
    }
    
    func draw(in view: MTKView) {
        
        if checkThreadgroupSize(for: view.drawableSize).hasZeroDimension {
            return
        }
        
        autoreleasepool {
            guard let drawable = view.currentDrawable else {
                print("currentDrawable nil!")
                return
            }
            
            guard let commandQueue = AppDelegate.shared.metal?.commandQueue else {
                return print("commandQueue nil, and we're drawing?")
            }
            
            guard let buffer = commandQueue.makeCommandBuffer(),
                let encoder = buffer.makeComputeCommandEncoder()
                else {
                    return print("buffer or encoder nil!")
            }
            
            encoder.setTexture(drawable.texture, index: 0)
            encoder.setComputePipelineState(pipeline)
            encoder.setBuffer(self.buffer, offset: 0, index: 0)
            
            encoder.dispatchThreadgroups(threadgroupSize!.threadgroupsPerGrid,
                                         threadsPerThreadgroup: threadgroupSize!.threadsPerThreadgroup)
            encoder.endEncoding()
            
            buffer.present(drawable)
            buffer.commit()
            buffer.waitUntilCompleted()
        }
    }
}
