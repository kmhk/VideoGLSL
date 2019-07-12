//
//  transition_burn.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//


#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

kernel void transition_burn(texture2d<float, access::read> inTexture [[ texture(0) ]],
                               texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                               texture2d<float, access::write> outTexture [[ texture(2) ]],
                               device const float *progress [[ buffer(0) ]],
                               device const float *sa [[ buffer(1) ]],
                               device const float *sg [[ buffer(2) ]],
                               device const float *sb [[ buffer(3) ]],
                               uint2 gid [[ thread_position_in_grid ]])
{
    
    float3 color = float3(*sa, *sg, *sb); /* = vec3(0.9, 0.4, 0.2) */;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    outTexture.write(mix(
               secOrig + float4(prog*color, 1.0),
               orig + float4((1.0-prog)*color, 1.0),
               prog
               ), gid);
}
