//
//  transition_glitch_displace.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>
#include <metal_geometric>

using namespace metal;


uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

float random(float2 co)
{
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,float2(a,b));
    float sn= fmod(dt,3.14);
    return fract(sin(sn) * c);
}
float voronoi( float2 x ) {
    float2 p = floor( x );
    float2 f = fract( x );
    float res = 8.0;
    for( float j=-1.; j<=1.; j++ )
        for( float i=-1.; i<=1.; i++ ) {
            float2  b = float2( i, j );
            float2  r = b - f + random( p + b );
            float d = dot( r, r );
            res = min( res, d );
        }
    return sqrt( res );
}

float2 displace(float4 tex, float2 texCoord, float dotDepth, float textureDepth, float strength) {
    float b = voronoi(.003 * texCoord + 2.0);
    float g = voronoi(0.2 * texCoord);
    float r = voronoi(texCoord - 1.0);
    float4 dt = tex * 1.0;
    float4 dis = dt * dotDepth + 1.0 - tex * textureDepth;
    
    dis.x = dis.x - 1.0 + textureDepth*dotDepth;
    dis.y = dis.y - 1.0 + textureDepth*dotDepth;
    dis.x *= strength;
    dis.y *= strength;
    float2 res_uv = texCoord ;
    res_uv.x = res_uv.x + dis.x - 0.0;
    res_uv.y = res_uv.y + dis.y;
    return res_uv;
}

float ease1(float t) {
    return t == 0.0 || t == 1.0
    ? t
    : t < 0.5
    ? +0.5 * pow(2.0, (20.0 * t) - 10.0)
    : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0;
}
float ease2(float t) {
    return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}



kernel void transition_glitchdisplace(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                      texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                      texture2d<float, access::write> outTexture [[ texture(2) ]],
                                      device const float *progress [[ buffer(0) ]],
                                      uint2 gid [[ thread_position_in_grid ]])
{
    
    float2 uv = float2(gid);
    float prog = *progress;
    
    uv.x /= inTexture.get_width();
    uv.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 p = uv.xy / float2(1.0).xy;
    float4 color1 = inTexture2.read(toUint2(p, inTexture2));
    float4 color2 = inTexture.read(toUint2(p, inTexture));
    float2 disp = displace(color1, p, 0.33, 0.7, 1.0-ease1(prog));
    float2 disp2 = displace(color2, p, 0.33, 0.5, ease2(prog));
    float4 dColor1 = inTexture.read(toUint2(disp, inTexture));
    float4 dColor2 = inTexture2.read(toUint2(disp2, inTexture2));
    float val = ease1(prog);
    float3 gray = float3(dot(min(dColor2, dColor1).rgb, float3(0.299, 0.587, 0.114)));
    dColor2 = float4(gray, 1.0);
    dColor2 *= 2.0;
    color1 = mix(color1, dColor2, smoothstep(0.0, 0.5, prog));
    color2 = mix(color2, dColor1, smoothstep(1.0, 0.5, prog));
    outTexture.write(mix(color1, color2, val), gid);
    
}

