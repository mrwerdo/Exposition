#include <metal_stdlib>
#include <metal_math>

using namespace metal;

/// Convert a point on the screen to a point in the complex plane.
inline float2 screenToComplex(float2 point, float2 size, float2 zoom)
{
    const float scale = max(zoom.x/size.x, zoom.y/size.y);
    return (point - size/2) * scale;
}

inline float2 cross(float2 a, float2 b) {
    // <a.x, a.y> x <b.x, b.y>
    float real = a.x * b.x - a.y * b.y;
    float imag = a.y * b.x + a.x * b.y;
    return float2(real, imag);
}

inline float2 div(float2 a, float2 b) {
    float modulus = b.x * b.x + b.y * b.y;
    float real = a.x * b.x + a.y * b.y;
    float imag = a.y * b.x - a.x * b.y;
    return float2(real/modulus, imag/modulus);
}

inline float2 pow(float2 x, int times) {
    float r = pow(length(x), (float)times);
    float arg = atan2(x.y, x.x);
    return float2(r * cos(times * arg), r * sin(times * arg));
}

inline float factorial(int n) {
    float sum = 1;
    for (int i = 1; i <= n; i++) {
        sum *= i;
    }
    return sum;
}

inline float2 e(float2 x) {
    float2 sum = float2();
    for (int i = 0; i < 6; i++) {
        float2 numerator = pow(x, i);
        float denominator = factorial(i);
        sum += float2(numerator.x / denominator, numerator.y / denominator);
    }
    return sum;
}

inline float2 sin(float2 x) {
    float2 p1 = e(cross(float2(0, 1), x));
    float2 p2 = e(cross(float2(0, 1), -x));
    return div((p1 - p2), float2(0, 2));
}

inline float2 cos(float2 x) {
    float2 p1 = e(cross(float2(0, 1), x));
    float2 p2 = e(cross(float2(0, 1), -x));
    return div((p1 + p2), float2(2, 0));
}

float4 colorForIterationNewTon(float2 z, float2 c, int maxiters, float escape)
{
    float2 C = z;
    for (int i = 0; i < maxiters; i++) {
        // f(x) = √x
        // x_n1 = x_n0 - f(x)/f'(x)
        // f'(x) = 1/(2√x)
        
//        float2 q = div(cross(z, z) - 1, 2 * z);
//        z = z - cross(c, q);
//        z = z - cross(c, div(cross(z, z) - 1, 2*z));
        
//        float2 f_z = sqrt(z);
//        float2 df_z = div(1, 2*f_z);
//        z = z - cross(c, div(f_z, df_z));
        
//        float2 a1 =  cross(cross(float2(3, 0), z), z);
//        float2 a2 = cross(cross(z, z), z);
//        float2 a3 = div(a2 - float2(1, 0), a1);
//        z = z - cross(c, a3);
        
//        {\frac {(1-z^{3}/6)}{(z-z^{2}/2)^{2}}}+c
        
//        z = z - cross(c, div(f(z), df(z)));
//        z = z - div(c, cross(z, z));
        
        // Newton's method?
        // z1 = 0.5 * (z + z0/z)
//        float2 z2 = 0.5 * cross(c, z + div(C, z));
//        float2 z2 = cross(c,z - div(f(C), df(z)));
        
        float2 z2 = z - cross(c, div(sin(z), cos(z)));
        if (length(z2 - z) < 0.1) {
            float hue = (i+1-log2(log10(length_squared(z))/2))/maxiters*4 * M_PI_F + 3;
            return float4((cos(hue)+1)/2,
                          (-cos(hue+M_PI_F/3)+1)/2,
                          (-cos(hue-M_PI_F/3)+1)/2,
                          1);
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
    
    float2 z = screenToComplex(uposf - origin,
                               size,
                               zoom);
    float2 c = screenToComplex(screenPoint,
                               size,
                               zoom);
    
    output.write(float4(colorForIterationNewTon(z, c, 100, 50)), upos);
}
