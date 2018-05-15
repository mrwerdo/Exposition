//
//  Vector.swift
//  GeometryPackageDescription
//
//  Created by Andrew Thompson on 9/12/17.
//

import Foundation

public protocol VectorType: Comparable, Hashable {
    associatedtype Value: Numeric
    static var components: [WritableKeyPath<Self, Value>] { get }
    
    init()
}

public extension VectorType {
    init(components: [Value]) {
        self.init()
        for (property, value) in zip(Self.components, components) {
            self[keyPath: property] = value
        }
    }

    init<Other: VectorType>(otherVector vector: Other) where Other.Value == Self.Value {
        let components = Other.components.map { vector[keyPath: $0] }
        self.init(components: components)
    }
    
    init<Other: VectorType>(convertVector vector: Other, using conversion: ((Other.Value) -> Value)) {
        let components = Other.components.map { conversion(vector[keyPath: $0]) }
        self.init(components: components)
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        for p in Self.components where lhs[keyPath: p] != rhs[keyPath: p] {
            return false
        }
        return true
    }
    
    var hashValue: Int {
        return Self.components.description.hashValue // FIXME: This hash algorithm is inefficient.
    }
}

public extension VectorType {
    static func +(lhs: Self, rhs: Self) -> Self {
        return self.init(components: Self.components.map { lhs[keyPath: $0] + rhs[keyPath: $0] })
    }

    static func -(lhs: Self, rhs: Self) -> Self {
        return self.init(components: Self.components.map { lhs[keyPath: $0] - rhs[keyPath: $0] })
    }

    static func *(lhs: Self, rhs: Self) -> Self {
        return self.init(components: Self.components.map { lhs[keyPath: $0] * rhs[keyPath: $0] })
    }
    
    static func +=(lhs: inout Self, rhs: Self) {
        Self.components.forEach { lhs[keyPath: $0] += rhs[keyPath: $0] }
    }
    
    static func -=(lhs: inout Self, rhs: Self) {
        Self.components.forEach { lhs[keyPath: $0] -= rhs[keyPath: $0] }
    }
    
    static func *=(lhs: inout Self, rhs: Self) {
        Self.components.forEach { lhs[keyPath: $0] *= rhs[keyPath: $0] }
    }
}

public extension VectorType where Value: BinaryInteger {
    static func /(lhs: Self, rhs: Self) -> Self {
        return self.init(components: Self.components.map { lhs[keyPath: $0] / rhs[keyPath: $0] })
    }
    
    static func /=(lhs: inout Self, rhs: Self) {
        Self.components.forEach { lhs[keyPath: $0] /= rhs[keyPath: $0] }
    }
}

public extension VectorType where Value: SignedNumeric {
    static prefix func -(this: Self) -> Self {
        return self.init(components: Self.components.map { -this[keyPath: $0] })
    }
}

public extension VectorType where Value: Comparable {
    static func >(lhs: Self, rhs: Self) -> Bool {
        for p in Self.components where lhs[keyPath: p] <= rhs[keyPath: p] {
            return false
        }
        return true
    }

    static func <(lhs: Self, rhs: Self) -> Bool {
        for p in Self.components where lhs[keyPath: p] >= rhs[keyPath: p] {
            return false
        }
        return true
    }
}
