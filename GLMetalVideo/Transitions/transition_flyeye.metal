//
//  transition_flyeye.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

kernel void transition_flyeye(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                  texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                  texture2d<float, access::write> outTexture [[ texture(2) ]],
                                  device const float *progress [[ buffer(0) ]],
                                  device const float *Size [[ buffer(1) ]],
                                  device const float *Zoom [[ buffer(2) ]],
                                  device const float *color [[ buffer(3) ]],
                                  uint2 gid [[ thread_position_in_grid ]])
{
    float size = *Size;
    float zoom = *Zoom;
    float colorSeparation = *color;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float inv = 1. - prog;
    float2 disp = size*float2(cos(zoom*ngid.x), sin(zoom*ngid.y));
    float4 texTo = inTexture.read(toUint2(ngid + inv*disp, inTexture));
    float4 texFrom = float4(
                        inTexture2.read(toUint2(ngid + prog*disp*(1.0 - colorSeparation), inTexture2)).r,
                        inTexture2.read(toUint2(ngid + prog*disp, inTexture2)).g,
                        inTexture2.read(toUint2(ngid + prog*disp*(1.0 + colorSeparation), inTexture2)).b,
                        1.0);
    outTexture.write(texTo*prog + texFrom*inv, gid);
}

