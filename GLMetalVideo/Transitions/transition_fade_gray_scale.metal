//
//  transition_fade_gray_scale.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float3 grayscale (float3 color) {
    return float3(0.2126*color.r + 0.7152*color.g + 0.0722*color.b);
}

kernel void transition_fade_gray_scale(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                  texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                  texture2d<float, access::write> outTexture [[ texture(2) ]],
                                  device const float *progress [[ buffer(0) ]],
                                  device const float *inten [[ buffer(1) ]],
                                  uint2 gid [[ thread_position_in_grid ]])
{
    float intensity = *inten;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float4 fc = secOrig;
    float4 tc = orig;
    outTexture.write(mix(
               mix(float4(grayscale(fc.rgb), 1.0), fc, smoothstep(1.0-intensity, 0.0, prog)),
               mix(float4(grayscale(tc.rgb), 1.0), tc, smoothstep(    intensity, 1.0, prog)),
               prog), gid);
}
