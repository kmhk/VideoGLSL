//
//  transition_crazy_parametric_fun.metal
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

kernel void transition_crazy_parametric_fun(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                   texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<float, access::write> outTexture [[ texture(2) ]],
                                   device const float *progress [[ buffer(0) ]],
                                   device const float *a_ [[ buffer(1) ]],
                                   device const float *b_ [[ buffer(2) ]],
                                   device const float *ampl [[ buffer(3) ]],
                                   device const float *smooth [[ buffer(4) ]],
                                   uint2 gid [[ thread_position_in_grid ]])
{
    float a = *a_; // = 4
    float b = *b_; // = 1
    float amplitude = *ampl; // = 120
    float smoothness = *smooth; // = 0.1

    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 p = ngid.xy / float2(1.0).xy;
    float2 dir = p - float2(.5);
    float dist = length(dir);
    float x = (a - b) * cos(prog) + b * cos(prog * ((a / b) - 1.) );
    float y = (a - b) * sin(prog) - b * sin(prog * ((a / b) - 1.));
    float2 offset = dir * float2(sin(prog  * dist * amplitude * x), sin(prog * dist * amplitude * y)) / smoothness;
    outTexture.write(mix(inTexture.read(toUint2(p + offset, inTexture2)), inTexture.read(toUint2(p, inTexture)), smoothstep(0.2, 1.0, prog)), gid);
    
}
