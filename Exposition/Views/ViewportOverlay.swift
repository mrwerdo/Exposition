//
//  ViewPortOverlay.swift
//  Exposition
//
//  Created by Andrew Thompson on 21/6/19.
//  Copyright © 2019 Andrew Thompson. All rights reserved.
//

import Cocoa

protocol ParameterDelegate: class {
    func update(parameter: String, position: CGPoint, zoom: CGFloat, origin: CGPoint)
}

class ViewportOverlay: NSView {
    private var cursor: NSCursor = NSCursor.crosshair
    private var cursorIcon: NSImageView
    private var panRecognizer: NSPanGestureRecognizer = NSPanGestureRecognizer()
    
    public var showCursor: Bool = true {
        didSet {
            cursorIcon.isHidden = !showCursor
        }
    }
    
    public weak var delegate: ParameterDelegate? { didSet { notifyDelegate() } }
    
    public var defaultZoom: CGFloat = 3
    public var userInteractionEnabled: Bool = false
    public var cursorPosition: CGPoint = .zero  { didSet { notifyDelegate() } }
    public var zoom: CGFloat = 3                { didSet { notifyDelegate() } }
    public var origin: CGPoint = .zero          { didSet { notifyDelegate() } }
    public var name: String = ""
    
    private func notifyDelegate() {
        delegate?.update(parameter: name, position: cursorPosition, zoom: zoom, origin: origin)
    }
    
    public required init?(coder: NSCoder) {
        cursorIcon = NSImageView(image: cursor.image)
        cursorIcon.frame.size = CGSize(width: 20, height: 20)
        
        super.init(coder: coder)
        
        self.addSubview(cursorIcon)
    }
    
    public override var acceptsFirstResponder: Bool {
        return true
    }
    
    public override func mouseDown(with event: NSEvent) {
        updateCursor(with: event)
    }
    
    public override func mouseDragged(with event: NSEvent) {
        updateCursor(with: event)
    }
    
    public override func mouseUp(with event: NSEvent) {
        updateCursor(with: event)
    }
    
    private func updateCursor(with event: NSEvent) {
        let position = convert(event.locationInWindow, from: nil)
        cursorIcon.frame.center = position
        cursorPosition = position
    }
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        let size = oldSize
        let drawableSize = bounds.size
        let scale = CGSize(width: size.width / drawableSize.width, height: size.height / drawableSize.height)
        
        cursorPosition.x = cursorPosition.x * scale.width
        cursorPosition.y = cursorPosition.y * scale.height
        
        origin.x *= scale.width
        origin.y *= scale.height
        
        notifyDelegate()
    }
    
    public override func scrollWheel(with event: NSEvent) {
        origin = CGPoint(x: origin.x + event.scrollingDeltaX,
                         y: origin.y + event.scrollingDeltaY)
    }
    
    public override func magnify(with event: NSEvent) {
        zoom *= 1 - event.magnification
    }
    
    public override func smartMagnify(with event: NSEvent) {
        zoom *= 1.5
    }
    
    public func reset() {
        zoom = defaultZoom
        origin = .zero
        cursorPosition = .zero
    }
    
    public override func resetCursorRects() {
        addCursorRect(bounds, cursor: cursor)
    }
}
