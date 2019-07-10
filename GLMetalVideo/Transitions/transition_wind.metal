//
//  transition_wind.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/10/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>

using namespace metal;


float rand (float2 co) {
    return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

kernel void transition_wind(texture2d<float, access::read> inTexture [[ texture(0) ]],
                            texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                            texture2d<float, access::write> outTexture [[ texture(2) ]],
                            device const float *progress [[ buffer(0) ]],
                            uint2 gid [[ thread_position_in_grid ]])
{
    
    float transition_wind_size = 0.2;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float r = rand(float2(0, ngid.y));
    float m = smoothstep(0.0, -transition_wind_size, ngid.x*(1.0-transition_wind_size) + transition_wind_size*r - (prog * (1.0 + transition_wind_size)));
    
    outTexture.write(mix(
                         secOrig,
                         orig,
                         m), gid);
}

