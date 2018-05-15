// -----------------------------------------------------------------------------
// MARK: - Coordinate Concrete Types
// -----------------------------------------------------------------------------

public struct Point2D : VectorType {
    
    public var x: Int
    public var y: Int
    
    public init() {
        x = 0
        y = 0
    }
    
    public init(x: Int = 0, y: Int = 0) {
        self.x = x
        self.y = y
    }
    
    static public var components: [WritableKeyPath<Point2D, Int>] {
        return [\.x, \.y]
    }
}

public struct Point3D : VectorType {
    public var x: Int = 0
    public var y: Int = 0
    public var z: Int = 0
    
    public static var components: [WritableKeyPath<Point3D, Int>] {
        return [\.x, \.y, \.z]
    }

    public init() { }
    
    public init(x: Int = 0, y: Int = 0, z: Int = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(tuple: (x: Int, y: Int, z: Int)) {
        self.x = tuple.x
        self.y = tuple.y
        self.z = tuple.z
    }
}

public struct Size2D : CountableArea {
    public var width: Int = 0
    public var height: Int = 0
    
    public init() { }
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}


public struct Size3D : CountableVolume {
    public var width: Int = 0
    public var height: Int = 0
    public var breadth: Int = 0
    
    public init() { }
    
    public init(width: Int, height: Int, breadth: Int) {
        self.width = width
        self.height = height
        self.breadth = breadth
    }
    
    public var verticies: [Point3D] {
        typealias P = Point3D
        return [ P(x: 0,y: 0,z: 0),
                 P(x: 0,y: 0,z: breadth),
                 P(x: 0,y: height, z: 0),
                 P(x: 0, y: height, z: breadth),
                 P(x: width, y: 0, z: 0),
                 P(x: width, y: 0, z: breadth),
                 P(x: width, y: height, z: 0),
                 P(x: width, y: height, z: breadth)
        ]
    }
}

extension Point3D : Hashable {
    public var hashValue: Int {
        return x.hashValue ^ y.hashValue << 16 ^ z.hashValue << 32
    }
}

extension Size3D : Hashable {
    public var hashValue: Int {
        return width.hashValue ^ height.hashValue << 16 ^ breadth.hashValue << 32
    }
    
    var coordinates: [Point3D] {
        var cs = [Point3D]()
        cs.reserveCapacity(volume)
        for x in 0..<width {
            for y in 0..<height {
                for z in 0..<breadth {
                    cs.append(Point3D(x: x, y: y, z: z))
                }
            }
        }
        return cs
    }
}
