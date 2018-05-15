#include <metal_stdlib>
#include <metal_math>

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


#ifndef iterator
#define iterator (z - c * ((z * z * z) - 1)/(3 * (z * z)))
#endif

using namespace metal;

constant bool use_escape_iteration [[ function_constant(0) ]];

/// Convert a point on the screen to a point in the complex plane.
inline float2 screenToComplex(float2 point, float2 size, float2 zoom)
{
    const float scale = max(zoom.x/size.x, zoom.y/size.y);
    return (point - size/2) * scale;
}

inline float4 colorForIterationNewton(Complex z, Complex c, int i, int maxiters, float escape)
{
    float hue = (i+1-log2(log10(z.length_squared())/2))/maxiters*4 * M_PI_F + 3;
    return float4((cos(hue)+1)/2,
                  (-cos(hue+M_PI_F/3)+1)/2,
                  (-cos(hue-M_PI_F/3)+1)/2,
                  1);
}

inline Complex function(Complex z, Complex c, Complex Z, Complex C) {
//    return z - c * sin(z)/cos(z);
//    return z - c * (z * z * z- Complex(1, 0))/(Complex(3, 0) * z * z);
    return iterator;
//    return z - c * (Complex(0.5, 0) * z + 1/z);
//    return z - c * cos(z)/(-sin(z));
//    return z - c * (z ^ p)/(Complex(p, 0) * z ** (-2.0/3.0));
//    return z*z + c;
}

float4 iterate(Complex Z, Complex C, int maxiters, float escape) {
    Complex c = C;
    Complex z = Z;
    for (int i = 0; i < maxiters; i++) {
        Complex z2 = function(z, c, Z, C);
        if (use_escape_iteration) {
            if (z2.length_squared() > escape) return colorForIterationNewton(z2, c, i, maxiters, escape);
        } else {
            if ((z2 - z).length() < 0.00001) return colorForIterationNewton(z2, c, i, maxiters, escape);
        }
        z = z2;
    }
    return float4(0, 0, 0, 1);
}


kernel void newtonShader(texture2d<float, access::write> output [[texture(0)]],
                         uint2 upos [[thread_position_in_grid]],
                         const device float2* parameters [[buffer(0)]])
{
    uint width = output.get_width();
    uint height = output.get_height();
    if (upos.x > width || upos.y > height) return;
    
    const device float2& screenPoint = parameters[0];
    const device float2& origin = parameters[1];
    const device float2& zoom = parameters[2];
    
    float2 uposf = float2(upos.x, upos.y);
    float2 size = float2(width, height);
    
    Complex z = screenToComplex(uposf - origin,
                               size,
                               zoom);
    Complex c = screenToComplex(screenPoint,
                               size,
                               zoom);
    
    output.write(iterate(z, c, 100, 50), upos);
}
