//
//  transition_directional_wipe.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

kernel void transition_directional_wipe(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                        texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                        texture2d<float, access::write> outTexture [[ texture(2) ]],
                                        device const float *progress [[ buffer(0) ]],
                                        device const float *dx [[ buffer(1) ]],
                                        device const float *dy [[ buffer(2) ]],
                                        device const float *thres [[ buffer(3) ]],
                                        uint2 gid [[ thread_position_in_grid ]])
{
    float2 direction = float2(*dx, *dy);
    float smoothness = *thres;
    const float2 center = float2(0.5, 0.5);
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 v = normalize(direction);
    v /= abs(v.x)+abs(v.y);
    float d = v.x * center.x + v.y * center.y;
    float m =
    (1.0-step(prog, 0.0)) * // there is something wrong with our formula that makes m not equals 0.0 with progress is 0.0
    (1.0 - smoothstep(-smoothness, 0.0, v.x * ngid.x + v.y * ngid.y - (d-0.5+prog*(1.+smoothness))));
    outTexture.write(mix(secOrig, orig, m), gid);
    
}
