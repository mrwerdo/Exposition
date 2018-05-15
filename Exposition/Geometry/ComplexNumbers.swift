import Foundation

public struct Complex : Equatable, CustomStringConvertible, Hashable {
    public static var accuraccy: Double = 0.00001
    public var real: Double
    public var imaginary: Double
    
    public init() {
        self.init(0, 0)
    }
    public init(_ real: Double, _ imaginary: Double) {
        self.real = real
        self.imaginary = imaginary
    }
    
    public init(_ point: CGPoint) {
        self.init(Double(point.x), Double(point.y))
    }
    
    public var description: String {
        let r = String(format: "%f", real)
        let i = String(format: "%f", abs(imaginary))
        var result = ""
        switch (real, imaginary) {
        case _ where imaginary == 0:
            result = "\(r)"
        case _ where real == 0:
            result = "\(i)𝒊"
        case _ where imaginary < 0:
            result = "\(r) - \(i)𝒊"
        default:
            result = "\(r) + \(i)𝒊"
        }
        return result
    }
    
    public var arg: Double {
       return atan2(imaginary, real)
    }
    
    public var hashValue: Int {
        return Int(real) ^ Int(imaginary)
    }
}

public func ==(lhs: Complex, rhs: Complex) -> Bool {
    return lhs.real == rhs.real && lhs.imaginary == rhs.imaginary
}
public func +(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real + rhs.real, lhs.imaginary + rhs.imaginary)
}
public func -(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real - rhs.real, lhs.imaginary - rhs.imaginary)
}
public prefix func -(c1: Complex) -> Complex {
    return Complex(-c1.real, -c1.imaginary)
}
public func *(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real * rhs.real - lhs.imaginary * rhs.imaginary, lhs.real * rhs.imaginary + rhs.real * lhs.imaginary)
}
public func /(lhs: Complex, rhs: Complex) -> Complex {
    let denominator = (rhs.real * rhs.real + rhs.imaginary * rhs.imaginary)
    return Complex((lhs.real * rhs.real + lhs.imaginary * rhs.imaginary) / denominator,
                    (lhs.imaginary * rhs.real - lhs.real * rhs.imaginary) / denominator)
}

// -----------------------------------------------------------------------------
//                          Assignment Operators
// -----------------------------------------------------------------------------

public func +=(lhs: inout Complex, rhs: Complex) {
    lhs = lhs + rhs
}
public func -=(lhs: inout Complex, rhs: Complex) {
    lhs = lhs - rhs
}
public func *=(lhs: inout Complex, rhs: Complex) {
    lhs = lhs * rhs
}
public func /=(lhs: inout Complex, rhs: Complex) {
    lhs = lhs / rhs
}

// -----------------------------------------------------------------------------
//                    Complex Numebrs and other Numbers
// -----------------------------------------------------------------------------

public func +(lhs: Double, rhs: Complex) -> Complex { // Real plus imaginary
    return Complex(lhs + rhs.real, rhs.imaginary)
}
public func -(lhs: Double, rhs: Complex) -> Complex { // Real minus imaginary
    return Complex(lhs - rhs.real, -rhs.imaginary)
}
public func *(lhs: Double, rhs: Complex) -> Complex { // Real times imaginary
    return Complex(lhs * rhs.real, lhs * rhs.imaginary)
}
public func /(lhs: Double, rhs: Complex) -> Complex { // Real divide imaginary
    return Complex(lhs / rhs.real, lhs / rhs.imaginary)
}

public func /(lhs: Complex, rhs: Double) -> Complex { // Imaginary divide real
    return Complex(lhs.real / rhs, lhs.imaginary / rhs)
}
public func -(lhs: Complex, rhs: Double) -> Complex { // Imaginary minus real
    return Complex(lhs.real - rhs, lhs.imaginary)
}
public func +(lhs: Complex, rhs: Double) -> Complex { // Imaginary plus real
    return Complex(lhs.real + rhs, lhs.imaginary)
}
public func *(lhs: Complex, rhs: Double) -> Complex { // Imaginary times real
    return Complex(lhs.real * rhs, lhs.imaginary * rhs)
}

// -----------------------------------------------------------------------------
//                              Functions
// -----------------------------------------------------------------------------

public func abs(_ n: Complex) -> Double {
    return sqrt(n.real * n.real + n.imaginary * n.imaginary)
}

public func modulus(_ n: Complex) -> Double {
    return abs(n)
}

public func **(lhs: Double, rhs: Double) -> Double {
    return pow(lhs, rhs)
}

public func pow(_ base: Complex, _ n: Double) -> Complex {
    let r = modulus(base) ** n
    let arg = base.arg
    let real = r * cos(n * arg)
    let imaginary = r * sin(n * arg)
    return Complex(real, imaginary)
}

infix operator ** : MultiplicationPrecedence

public func **(base: Complex, n: Double) -> Complex {
    return pow(base, n)
}

public func **(base: Complex, n: Int) -> Complex {
    return pow(base, Double(n))
}

public func factorial(_ n: Int) -> Int {
    if n == 0 {
        return 1
    }
    var sum = 1
    for it in 1...n {
        sum *= it
    }
    return sum
}

public func e(_ x: Double, accuracy: Int = 5) -> Double {
    var sum = 0.0
    for n in 0...accuracy {
        sum += x ** Double(n) / Double(factorial(n))
    }
    return sum
}

public func e(_ x: Complex, accuracy: Int = 5) -> Complex {
    let r = e(x.real, accuracy: accuracy)
    return Complex(cos(x.imaginary), sin(x.imaginary)) * r
}

public func sin(theta: Complex) -> Complex {
    let p1 = e(Complex(0, 1) * theta)
    let p2 = e(Complex(0, 1) * -theta)
    return (p1 - p2) / (2 * Complex(0, 1))
}

public func cos(theta: Complex) -> Complex {
    let p1 = e(Complex(0, 1) * theta)
    let p2 = e(Complex(0, 1) * -theta)
    return (p1 + p2) / 2
}

public struct ComplexRect : Equatable, CustomStringConvertible {
    public var topLeft: Complex
    public var bottomRight: Complex
    
    public var bottomLeft: Complex {
        return Complex(topLeft.real, bottomRight.imaginary)
    }
    
    public var topRight: Complex {
        return Complex(bottomRight.real, topLeft.imaginary)
    }
    
    public init(point c1: Complex, oppositePoint c2: Complex) {
        topLeft = Complex(min(c1.real, c2.real), max(c1.imaginary, c2.imaginary))
        bottomRight = Complex(max(c1.real, c2.real), min(c1.imaginary, c2.imaginary))
    }
    
    private init(_ topLeft: Complex, _ bottomRight: Complex) {
        self.topLeft = topLeft
        self.bottomRight = bottomRight
    }
    
    public var description: String {
        return "tl: \(topLeft), br: \(bottomRight), bl: \(bottomLeft), tr: \(topRight)"
    }
    
    public mutating func translate(by amount: Complex) {
        topLeft += amount
        bottomRight += amount
    }
}

public func ==(lhs: ComplexRect, rhs: ComplexRect) -> Bool {
    return (lhs.topLeft == rhs.topLeft) && (lhs.bottomRight == rhs.bottomRight)
}
