//
//  transition_angular.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

kernel void transition_angular(texture2d<float, access::read> inTexture [[ texture(0) ]],
                              texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                              texture2d<float, access::write> outTexture [[ texture(2) ]],
                              device const float *progress [[ buffer(0) ]],
                              device const int *starting [[ buffer(1) ]],
                              uint2 gid [[ thread_position_in_grid ]])
{
    float startingAngle = *starting; // = 90;

    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float offset = startingAngle * PI / 180.0;
    float angle = atan2(ngid.y - 0.5, ngid.x - 0.5) + offset;
    float normalizedAngle = (angle + PI) / (2.0 * PI);
    
    normalizedAngle = normalizedAngle - floor(normalizedAngle);
    
    outTexture.write(mix(
                         secOrig,
                         orig,
                         step(normalizedAngle, prog)
                         ), gid);
}


