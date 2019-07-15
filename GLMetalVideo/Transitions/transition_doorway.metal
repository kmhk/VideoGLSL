//
//  transition_doorway.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
#include <metal_common>

using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

bool inBounds (float2 p);

float2 project (float2 p) {
    return p * float2(1.0, -1.2) + float2(0.0, -0.02);
}

float4 bgColor (float2 p, float2 pto, float reflection, float4 to) {
    float4 c = float4(0.0, 0.0, 0.0, 1.0);
    pto = project(pto);
    if (inBounds(pto)) {
        c += mix(float4(0.0, 0.0, 0.0, 1.0), to/*getToColor(pto)*/, reflection * mix(1.0, 0.0, pto.y));
    }
    return c;
}

kernel void transition_doorway(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                   texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<float, access::write> outTexture [[ texture(2) ]],
                                   device const float *progress [[ buffer(0) ]],
                                   device const float *reflect_ [[ buffer(1) ]],
                                   device const float *persp [[ buffer(2) ]],
                                   device const float *depth_ [[ buffer(3) ]],
                                   uint2 gid [[ thread_position_in_grid ]])
{
    float reflection = *reflect_; // = 0.4
    float perspective = *persp; // = 0.4
    float depth = *depth_; // = 3
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 pfr = float2(-1.), pto = float2(-1.);
    float middleSlit = 2.0 * abs(ngid.x-0.5) - prog;
    if (middleSlit > 0.0) {
        pfr = ngid + (ngid.x > 0.5 ? -1.0 : 1.0) * float2(0.5*prog, 0.0);
        float d = 1.0/(1.0+perspective*prog*(1.0-middleSlit));
        pfr.y -= d/2.;
        pfr.y *= d;
        pfr.y += d/2.;
    }
    float size = mix(1.0, depth, 1.-prog);
    pto = (ngid + float2(-0.5, -0.5)) * float2(size, size) + float2(0.5, 0.5);
    if (inBounds(pfr)) {
        outTexture.write(inTexture2.read(toUint2(pfr, inTexture2)), gid);
    }
    else if (inBounds(pto)) {
        outTexture.write(inTexture.read(toUint2(pto, inTexture)), gid);
    }
    else {
        outTexture.write(bgColor(ngid, pto, reflection, inTexture.read(toUint2(pto, inTexture))), gid);
    }
    
}

