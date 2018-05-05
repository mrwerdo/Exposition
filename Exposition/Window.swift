//
//  Window.swift
//  Exposition
//
//  Created by Andrew Thompson on 5/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Cocoa

class Window: NSWindow {
    override func mouseDragged(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            let p = frame.origin
            self.setFrameOrigin(CGPoint(x: p.x + event.deltaX, y: p.y - event.deltaY))
        }
    }
}
