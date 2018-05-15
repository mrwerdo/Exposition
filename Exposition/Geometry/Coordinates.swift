import Foundation

public protocol CountableArea : VectorType {
    associatedtype Measure: Numeric
    
    var width: Measure { get set }
    var height: Measure { get set }
    var area: Measure { get }
}

public extension CountableArea {
    static var components: [WritableKeyPath<Self, Measure>] {
        return [\.width, \.height]
    }

    var hashValue: Int {
        return "\(width), \(height)".hashValue
    }
    
    var area: Measure {
        return width * height
    }
    
    public static func ==(a: Self, b: Self) -> Bool {
        return a.width == b.width && a.height == b.height
    }
}
    
public extension CountableArea where Measure: Comparable {
    public static func <(a: Self, b: Self) -> Bool {
        return a.area < b.area
    }
    
    public static func >(a: Self, b: Self) -> Bool {
        return a.area > b.area
    }
}

public extension CountableArea where Measure == Int {
    func iterateCoordinates(apply: (Point2D) -> ()) {
        for x in 0..<width {
            for y in 0..<height {
                apply(Point2D(x: x, y: y))
            }
        }
    }
}

public protocol CountableVolume : VectorType {
    associatedtype Measure: Numeric
    
    var width: Measure { get set }
    var height: Measure { get set }
    var breadth: Measure { get set }
    var volume: Measure { get }
}

public extension CountableVolume {
    static var components: [WritableKeyPath<Self, Measure>] {
        return [\.width, \.height, \.breadth]
    }
    
    var volume: Measure {
        return width * height * breadth
    }
    
    public static func ==(a: Self, b: Self) -> Bool {
        return a.width == b.width && a.height == b.height && a.breadth == b.breadth
    }
    
}

public extension CountableVolume where Measure: Comparable {
    public static func <(a: Self, b: Self) -> Bool {
        return a.volume < b.volume
    }
    
    public static func >(a: Self, b: Self) -> Bool {
        return a.volume > b.volume
    }
}

public extension CountableVolume where Measure == Int {
    public func iterateCoordinates(apply: (Point3D) throws -> ()) rethrows {
        for x in 0..<width {
            for y in 0..<height {
                for z in 0..<breadth {
                    try apply(Point3D(x: x, y: y, z: z))
                }
            }
        }
    }
}

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

// -----------------------------------------------------------------------------
// MARK: - Coordinate Protocol Conformance
// -----------------------------------------------------------------------------

extension CGPoint {
    func heading(to point: CGPoint) -> CGFloat {
        let difference = point - self
        return atan2(difference.y, difference.x)
    }
    
    func vector(headingTo point: CGPoint, speed: CGFloat) -> CGVector {
        let difference = point - self
        let theta = atan2(difference.y, difference.x)
        return CGVector(dx: speed * cos(theta), dy: speed * sin(theta))
    }
}

extension CGPoint : VectorType {
    public static var components: [WritableKeyPath<CGPoint, CGFloat>] {
        return [\.x, \.y]
    }
    
    public init(x: CGFloat) {
        self.init(x: x, y: 0)
    }
    
    public init(y: CGFloat) {
        self.init(x: 0, y: y)
    }
    
    public init(_ size: CGSize) {
        self.init(x: size.width, y: size.height)
    }

    init(_ v: CGVector) {
        self.init(x: v.dx, y: v.dy)
    }
    
    func distance(to p: CGPoint) -> CGFloat {
        let m = p - self
        return sqrt(m.x * m.x + m.y * m.y)
    }
}


extension CGVector : VectorType {
    public static var components: [WritableKeyPath<CGVector, CGFloat>] {
        return [\.dx, \.dy]
    }
}

extension CGSize : CountableArea {
    public init(square l: CGFloat) {
        self.init(width: l, height: l)
    }
}

extension CGRect {
    public var center: CGPoint {
        get {
            return CGPoint(x: width / 2, y: height / 2) + origin
        }
        set {
            let k = CGPoint(x: width / 2, y: height / 2)
            origin = newValue - k
        }
    }
    
    public var corners: [CGPoint] {
        let a = origin
        let b = origin + CGPoint(x: size.width, y: 0)
        let c = origin + CGPoint(x: 0, y: size.height)
        let d = origin + CGPoint(x: size.width, y: size.height)
        
        return [a, b, c, d]
    }
}
