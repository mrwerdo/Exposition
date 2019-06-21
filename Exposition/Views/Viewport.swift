//
//  MetalView.swift
//  Exposition
//
//  Created by Andrew Thompson on 21/6/19.
//  Copyright © 2019 Andrew Thompson. All rights reserved.
//

import Cocoa
import MetalKit

public func log(caller: String = #function, line: Int = #line, column: Int = #column, _ message: String = "") {
    print(Date(), "line: \(line), column: \(column), function: \(caller)")
}

class Viewport: MTKView {
    var cursorPosition: CGPoint = .zero { didSet { setNeedsDisplay(bounds) } }
    var zoom: CGFloat = 1.0             { didSet { setNeedsDisplay(bounds) } }
    var origin: CGPoint = .zero         { didSet { setNeedsDisplay(bounds) } }
    var shader: Shader?                 { didSet { setNeedsDisplay(bounds) } }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        autoResizeDrawable = true
        enableSetNeedsDisplay = true
        isPaused = true
        framebufferOnly = false
        preferredFramesPerSecond = 30
    }
    
    override func draw(_ dirtyRect: NSRect) {
        shader?.initaliseBuffer(cursor: cursorPosition, zoom: CGSize(width: zoom, height: zoom), origin: origin)
        shader?.draw(in: self)
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
//        log("transitioned from \(oldSize) to \(bounds.size)")
        let size = bounds.size
        let scale = CGSize(width: size.width / drawableSize.width, height: size.height / drawableSize.height)
        cursorPosition.x *= scale.width
        cursorPosition.y *= scale.height
        origin.x *= scale.width
        origin.y *= scale.height
        _ = shader?.checkThreadgroupSize(for: size)
    }
}
