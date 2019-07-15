//
//  transition_hexagon.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/15/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

struct Hexagon {
    float q;
    float r;
    float s;
};

Hexagon createHexagon(float q, float r){
    Hexagon hex;
    hex.q = q;
    hex.r = r;
    hex.s = -q - r;
    return hex;
}

Hexagon roundHexagon(Hexagon hex){
    
    float q = floor(hex.q + 0.5);
    float r = floor(hex.r + 0.5);
    float s = floor(hex.s + 0.5);
    
    float deltaQ = abs(q - hex.q);
    float deltaR = abs(r - hex.r);
    float deltaS = abs(s - hex.s);
    
    if (deltaQ > deltaR && deltaQ > deltaS)
        q = -r - s;
    else if (deltaR > deltaS)
        r = -q - s;
    else
        s = -q - r;
    
    return createHexagon(q, r);
}

Hexagon hexagonFromPoint(float2 point, float size, float ratio) {
    
    point.y /= ratio;
    point = (point - 0.5) / size;
    
    float q = (sqrt(3.0) / 3.0) * point.x + (-1.0 / 3.0) * point.y;
    float r = 0.0 * point.x + 2.0 / 3.0 * point.y;
    
    Hexagon hex = createHexagon(q, r);
    return roundHexagon(hex);
    
}

float2 pointFromHexagon(Hexagon hex, float size, float ratio) {
    
    float x = (sqrt(3.0) * hex.q + (sqrt(3.0) / 2.0) * hex.r) * size + 0.5;
    float y = (0.0 * hex.q + (3.0 / 2.0) * hex.r) * size + 0.5;
    
    return float2(x, y * ratio);
}

kernel void transition_hexagon(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                        texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                        texture2d<float, access::write> outTexture [[ texture(2) ]],
                                        device const float *prog [[ buffer(0) ]],
                                        device const int *steps_ [[ buffer(1) ]],
                                        device const float *horizontal [[ buffer(2) ]],
                                        uint2 gid [[ thread_position_in_grid ]])
{
    int steps = *steps_;
    float horizontalHexagons = *horizontal;
    float ratio = inTexture.get_width() / inTexture.get_height();
    
    float2 ngid = float2(gid);
    float progress = *prog;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float dist = 2.0 * min(progress, 1.0 - progress);
    dist = steps > 0 ? ceil(dist * float(steps)) / float(steps) : dist;
    
    float size = (sqrt(3.0) / 3.0) * dist / horizontalHexagons;
    
    float2 point = dist > 0.0 ? pointFromHexagon(hexagonFromPoint(ngid, size, ratio), size, ratio) : ngid;
    
    outTexture.write(mix(inTexture2.read(toUint2(point, inTexture2)), inTexture.read(toUint2(point, inTexture)), progress), gid);
    
    
}
