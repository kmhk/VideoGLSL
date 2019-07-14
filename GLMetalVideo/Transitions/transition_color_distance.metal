//
//  transition_color_distance.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

kernel void transition_color_distance(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                   texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<float, access::write> outTexture [[ texture(2) ]],
                                   device const float *progress [[ buffer(0) ]],
                                   device const float *power_ [[ buffer(1) ]],
                                   uint2 gid [[ thread_position_in_grid ]])
{
    float power = *power_; // = 5.0
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float m = step(distance(secOrig, orig), prog);
    outTexture.write(mix(
               mix(secOrig, orig, m),
               orig,
               pow(prog, power)
               ), gid);
    
}
