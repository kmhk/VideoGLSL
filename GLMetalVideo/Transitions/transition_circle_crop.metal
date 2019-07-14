//
//  transition_circle_crop.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

kernel void transition_circle_crop(texture2d<float, access::read> inTexture [[ texture(0) ]],
                               texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                               texture2d<float, access::write> outTexture [[ texture(2) ]],
                               device const float *progress [[ buffer(0) ]],
                               device const float *sa [[ buffer(1) ]],
                               device const float *sg [[ buffer(2) ]],
                               device const float *sb [[ buffer(3) ]],
                               device const float *salpha [[ buffer(4) ]],
                               device const float *ratio [[ buffer(5) ]],
                               uint2 gid [[ thread_position_in_grid ]])
{
    float4 bgcolor = float4(*sa, *sg, *sb, *salpha); // = float4(0.0, 0.0, 0.0, 1.0)
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    float2 ratio2 = float2(1.0, 1.0 / *ratio);
    float s = pow(2.0 * abs(prog - 0.5), 3.0);

    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float dist = length((ngid - 0.5) * ratio2);
    outTexture.write(mix(
               prog < 0.5 ? secOrig : orig, // branching is ok here as we statically depend on progress uniform (branching won't change over pixels)
               bgcolor,
               step(s, dist)
               ), gid);
    
}
