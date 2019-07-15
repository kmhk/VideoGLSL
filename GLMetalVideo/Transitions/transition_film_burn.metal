//
//  transition_film_burn.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//


#include <metal_stdlib>
using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

float sigmoid(float x, float a) {
    float b = pow(x*2.,a)/2.;
    if (x > .5) {
        b = 1.-pow(2.-(x*2.),a)/2.;
    }
    return b;
}
float rand(float co, float Seed){
    return fract(sin((co*24.9898)+Seed)*43758.5453);
}
float rand(float2 co);
float apow(float a,float b) { return pow(abs(a),b)*sign(b); }
float3 pow3(float3 a,float3 b) { return float3(apow(a.r,b.r),apow(a.g,b.g),apow(a.b,b.b)); }
float smooth_mix(float a,float b,float c) { return mix(a,b,sigmoid(c,2.)); }
float random(float2 co, float shft, float Seed){
    co += 10.;
    return smooth_mix(fract(sin(dot(co.xy ,float2(12.9898+(floor(shft)*.5),78.233+Seed))) * 43758.5453),fract(sin(dot(co.xy ,float2(12.9898+(floor(shft+1.)*.5),78.233+Seed))) * 43758.5453),fract(shft));
}
float smooth_random(float2 co, float shft, float Seed) {
    return smooth_mix(smooth_mix(random(floor(co),shft,Seed),random(floor(co+float2(1.,0.)),shft,Seed),fract(co.x)),smooth_mix(random(floor(co+float2(0.,1.)),shft,Seed),random(floor(co+float2(1.,1.)),shft,Seed),fract(co.x)),fract(co.y));
}
float4 texture(float2 p, float4 from, float4 to, float progress) {
    return mix(from, to, sigmoid(progress,10.));
}
#define pi 3.14159265358979323
#define clamps(x) clamp(x,0.,1.)

kernel void transition_film_burn(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                       texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                       texture2d<float, access::write> outTexture [[ texture(2) ]],
                                       device const float *progress [[ buffer(0) ]],
                                       device const float *seed [[ buffer(1) ]],
                                       uint2 gid [[ thread_position_in_grid ]])
{
    float Seed = *seed;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    
    float3 f = float3(0.);
    for (float i = 0.; i < 13.; i++) {
        f += sin(((ngid.x*rand(i)*6.)+(prog*8.))+rand(i+1.43))*sin(((ngid.y*rand(i+4.4)*6.)+(prog*6.))+rand(i+2.4));
        f += 1.-clamps(length(ngid-float2(smooth_random(float2(prog*1.3),i+1.,Seed),smooth_random(float2(prog*.5),i+6.25, Seed)))*mix(20.,70.,rand(i)));
    }
    f += 4.;
    f /= 11.;
    f = pow3(f*float3(1.,0.7,0.6),float3(1.,2.-sin(prog*pi),1.3));
    f *= sin(prog*pi);
    
    ngid -= .5;
    ngid *= 1.+(smooth_random(float2(prog*5.),6.3,Seed)*sin(prog*pi)*.05);
    ngid += .5;
    
    float4 blurred_image = float4(0.);
    float bluramount = sin(prog*pi)*.03;
#define repeats  50.
    for (float i = 0.; i < repeats; i++) {
        float2 q = float2(cos((i/repeats)*pi*2.),sin((i/repeats)*360.*pi*2)) *  (rand(float2(i,ngid.x+ngid.y))+bluramount);
        float2 uv2 = ngid+(q*bluramount);
        blurred_image += texture(uv2, inTexture2.read(toUint2(uv2, inTexture2))
                                 ,inTexture2.read(toUint2(uv2, inTexture2)), prog);
    }
    blurred_image /= repeats;
    
    outTexture.write(blurred_image+float4(f,0.), gid);
}
