//
//  Complex.metal
//  Exposition
//
//  Created by Andrew Thompson on 12/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

#define ComplexOp(op, o) inline Complex operator op (o) const

class Complex {
    float2 z;
public:
    
    float x() const {
        return z.x;
    }
    
    float y() const {
        return z.y;
    }
    
    Complex(float x, float y) : z(x, y) { }
    Complex(float x) : z(x) { }
    Complex() : z() { }
    Complex(float2 zz) : z(zz) { }
    
    typedef const thread Complex& cpx;
    
    ComplexOp(+, cpx o) {
        return z + o.z;
    }
    
    ComplexOp(-, cpx o) {
        return z - o.z;
    }
    
    ComplexOp(*, cpx o) {
        return Complex(z.x * o.z.x - z.y * o.z.y,
                       z.y * o.z.x + z.x * o.z.y);
    }
    
    ComplexOp(/, cpx o) {
        float modulus = o.z.x * o.z.x + o.z.y * o.z.y;
        float real = z.x * o.z.x + z.y * o.z.y;
        float imag = z.y * o.z.x - z.x * o.z.y;
        return Complex(real/modulus, imag/modulus);
    }
    
    ComplexOp(+, float o) {
        return z + o;
    }
    
    ComplexOp(-, float o) {
        return z - o;
    }
    
    ComplexOp(*, float o) {
        return *this * Complex(o, 0);
    }
    
    ComplexOp(/, float o) {
        return *this / Complex(o, 0);
    }
    
    ComplexOp(^, float n) {
        float r = pow(metal::length(z), n);
        float arg = n * atan2(z.y, z.x);
        return Complex(r * cos(arg), r * sin(arg));
    }
    
    inline Complex operator - () const {
        return Complex(-z);
    }
    
    inline float length_squared() const {
        return metal::length_squared(z);
    }
    
    inline float length() const {
        return metal::length(z);
    }
};

inline Complex operator * (float lhs, Complex rhs) {
    return rhs * Complex(lhs, 0);
}

inline Complex operator / (float lhs, Complex rhs) {
    return Complex(lhs, 0) / rhs;
}

inline Complex operator + (float lhs, Complex rhs) {
    return Complex(lhs, 0) + rhs;
}

inline Complex operator - (float lhs, Complex rhs) {
    return Complex(lhs, 0) - rhs;
}

inline Complex e(const thread Complex& x) {
    Complex numerator = x;
    float denominator = 1;
    Complex sum = Complex(1, 0);
    for (int i = 2; i <= 6; i++) {
        sum = sum + Complex(numerator.x() / denominator, numerator.y() / denominator);
        numerator = numerator * x;
        denominator = denominator * i;
    }
    return sum;
}

inline Complex sin(const thread Complex& x) {
    Complex p1 = e(Complex(0, 1) * x);
    Complex p2 = e(Complex(0, 1) * -x);
    return (p1 - p2) / Complex(0, 2);
}

inline Complex cos(const thread Complex& x) {
    Complex p1 = e(Complex(0, 1) * x);
    Complex p2 = e(Complex(0, 1) * -x);
    return (p1 + p2) / Complex(2, 0);
}
