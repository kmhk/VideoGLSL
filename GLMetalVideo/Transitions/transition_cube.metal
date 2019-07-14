//
//  transition_cube.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

float2 project (float2 p, float floating) {
    return p * float2(1.0, -1.2) + float2(0.0, -floating/100.);
}

bool inBounds (float2 p) {
    return all(float2(0.0) < p) && all(p < float2(1.0));
}

float4 bgColor (float2 p, float2 pfr, float2 pto, float floating, float reflection, float4 from, float4 to) {
    float4 c = float4(0.0, 0.0, 0.0, 1.0);
    pfr = project(pfr, floating);
    // FIXME avoid branching might help perf!
    if (inBounds(pfr)) {
        c += mix(float4(0.0), from/*getFromColor(pfr)*/, reflection * mix(1.0, 0.0, pfr.y));
    }
    pto = project(pto, floating);
    if (inBounds(pto)) {
        c += mix(float4(0.0), to/*getToColor(pto)*/, reflection * mix(1.0, 0.0, pto.y));
    }
    return c;
}

// p : the position
// persp : the perspective in [ 0, 1 ]
// center : the xcenter in [0, 1] \ 0.5 excluded
float2 xskew (float2 p, float persp, float center) {
    float x = mix(p.x, 1.0-p.x, center);
    return (
            (
             float2( x, (p.y - 0.5*(1.0-persp) * x) / (1.0+(persp-1.0)*x) )
             - float2(0.5-abs(center - 0.5), 0.0)
             )
            * float2(0.5 / abs(center - 0.5) * (center<0.5 ? 1.0 : -1.0), 1.0)
            + float2(center<0.5 ? 0.0 : 1.0, 0.0)
            );
}


kernel void transition_cube(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                   texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<float, access::write> outTexture [[ texture(2) ]],
                                   device const float *progress [[ buffer(0) ]],
                                   device const float *persp_ [[ buffer(1) ]],
                                   device const float *uzoom [[ buffer(2) ]],
                                   device const float *refl [[ buffer(3) ]],
                                   device const float *floating_ [[ buffer(4) ]],
                                   uint2 gid [[ thread_position_in_grid ]])
{
    float persp = *persp_;
    float unzoom = *uzoom;
    float reflection = *refl;
    float floating = *floating_;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float uz = unzoom * 2.0*(0.5-abs(0.5 - prog));
    float2 p = -uz*0.5+(1.0+uz) * ngid;
    float2 fromP = xskew(
                       (p - float2(prog, 0.0)) / float2(1.0-prog, 1.0),
                       1.0-mix(prog, 0.0, persp),
                       0.0
                       );
    float2 toP = xskew(
                     p / float2(prog, 1.0),
                     mix(pow(prog, 2.0), 1.0, persp),
                     1.0
                     );
    // FIXME avoid branching might help perf!
    if (inBounds(fromP)) {
        outTexture.write(inTexture2.read(toUint2(fromP, inTexture2)), gid);
    }
    else if (inBounds(toP)) {
        outTexture.write(inTexture.read(toUint2(toP, inTexture)), gid);
    } else {
        outTexture.write(bgColor(ngid, fromP, toP, floating, reflection,
                                 inTexture2.read(toUint2(fromP, inTexture2)), inTexture.read(toUint2(toP, inTexture))), gid);
    }
    
}


