//
//  transition_bouncer.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

kernel void transition_bouncer(texture2d<float, access::read> inTexture [[ texture(0) ]],
                               texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                               texture2d<float, access::write> outTexture [[ texture(2) ]],
                               device const float *progress [[ buffer(0) ]],
                               device const float *sa [[ buffer(1) ]],
                               device const float *sg [[ buffer(2) ]],
                               device const float *sb [[ buffer(3) ]],
                               device const float *sal [[ buffer(4) ]],
                               device const float *sh [[ buffer(5) ]],
                               device const float *bounce [[ buffer(6) ]],
                               uint2 gid [[ thread_position_in_grid ]])
{
    
    float4 shadow_colour = float4(*sa, *sg, *sb, *sal); // = vec4(0.,0.,0.,.6)
    float shadow_height = *sh; // = 0.075
    float bounces = *bounce; // = 3.0
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float time = prog;
    float stime = sin(time * PI / 2.);
    float phase = time * PI * bounces;
    float y = (abs(cos(phase))) * (1.0 - stime);
    float d = ngid.y - y;
    
    float2 sec_loc = float2(ngid.x, ngid.y + (1.0 - y));
    float4 sec_tex = inTexture2.read(uint2(sec_loc.x * inTexture.get_width(), sec_loc.y * inTexture.get_height()));
    
    outTexture.write(mix(
               mix(
                   orig,
                   shadow_colour,
                   step(d, shadow_height) * (1. - mix(
                                                      ((d / shadow_height) * shadow_colour.a) + (1.0 - shadow_colour.a),
                                                      1.0,
                                                      smoothstep(0.95, 1., prog) // fade-out the shadow at the end
                                                      ))
                   ),
               sec_tex,
               step(d, 0.0)
               ), gid);
}
