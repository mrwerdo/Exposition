#include <metal_stdlib>
#include <metal_math>

#include "Complex.metal"

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
    return z - c * (z * z * z- Complex(1, 0))/(Complex(3, 0) * z * z);
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
            if ((z2 - z).length() < 0.001) return colorForIterationNewton(z2, c, i, maxiters, escape);
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
