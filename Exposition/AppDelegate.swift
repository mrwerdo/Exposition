//
//  AppDelegate.swift
//  Exposition
//
//  Created by Andrew Thompson on 5/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Cocoa

class MetalVars {
    var device: MTLDevice
    var library: MTLLibrary
    var commandQueue: MTLCommandQueue
    var shaders: [Shader] {
        if _shaders == nil {
            _shaders = Shader.makeShaders(metal: self)
        }
        return _shaders
    }
    private var _shaders: [Shader]!
    
    init?() {
        let devices = MTLCopyAllDevices().sorted {
            $0.recommendedMaxWorkingSetSize > $1.recommendedMaxWorkingSetSize
        }
        guard let bestMatch = devices.first else {
            return nil
        }
        
        device = bestMatch
        guard let lib = device.makeDefaultLibrary()  else {
            return nil
        }
        library = lib
        
        guard let queue = device.makeCommandQueue() else {
            return nil
        }
        commandQueue = queue
        _shaders = nil
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var metal: MetalVars? = MetalVars()
    
    static var shared: AppDelegate {
        return NSApplication.shared.delegate! as! AppDelegate
    }
}

