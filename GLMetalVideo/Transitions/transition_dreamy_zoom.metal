//
//  transition_dreamy_zoom.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define DEG2RAD 0.03926990816987241548078304229099 // 1/180*PI

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);


kernel void transition_dreamy_zoom(texture2d<float, access::read> inTexture [[ texture(0) ]],
                              texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                              texture2d<float, access::write> outTexture [[ texture(2) ]],
                              device const float *progress [[ buffer(0) ]],
                              device const float *rotation_ [[ buffer(1) ]],
                              device const float *scale_ [[ buffer(2) ]],
                              device const float *ratio_ [[ buffer(3) ]],
                              uint2 gid [[ thread_position_in_grid ]])
{
    float rotation = *rotation_; // = 6
    float scale = *scale_; // = 1.2
    
    float ratio = *ratio_;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    // Massage parameters
    float phase = prog < 0.5 ? prog * 2.0 : (prog - 0.5) * 2.0;
    float angleOffset = prog < 0.5 ? mix(0.0, rotation * DEG2RAD, phase) : mix(-rotation * DEG2RAD, 0.0, phase);
    float newScale = prog < 0.5 ? mix(1.0, scale, phase) : mix(scale, 1.0, phase);
    
    float2 center = float2(0, 0);
    
    // Calculate the source point
    float2 assumedCenter = float2(0.5, 0.5);
    float2 p = (ngid.xy - float2(0.5, 0.5)) / newScale * float2(ratio, 1.0);
    
    // This can probably be optimized (with distance())
    float angle = atan2(p.y, p.x) + angleOffset;
    float dist = distance(center, p);
    p.x = cos(angle) * dist / ratio + 0.5;
    p.y = sin(angle) * dist + 0.5;
    float4 c = prog < 0.5 ? inTexture2.read(toUint2(p, inTexture2)) : inTexture.read(toUint2(p, inTexture));
    
    // Finally, apply the color
    outTexture.write(c + (prog < 0.5 ? mix(0.0, 1.0, phase) : mix(1.0, 0.0, phase)), gid);
}
