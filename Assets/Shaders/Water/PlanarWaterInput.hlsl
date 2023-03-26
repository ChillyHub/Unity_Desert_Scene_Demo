#ifndef PLANAR_WATER_INPUT_INCLUDED
#define PLANAR_WATER_INPUT_INCLUDED

#include "Assets/Shaders/ShaderLibrary/Utility.hlsl"

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);
TEXTURE2D(_DisturbNoise);
SAMPLER(sampler_DisturbNoise);
TEXTURE2D(_WaveTex);
SAMPLER(sampler_WaveTex);

TEXTURE2D(_UVMappingTexture);
SAMPLER(sampler_UVMappingTexture);
TEXTURE2D(_UVSyncMappingTexture);
SAMPLER(sampler_UVSyncMappingTexture);
TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

CBUFFER_START(UnityPerMaterial)
    float4 _NormalMap_ST;
    float4 _DisturbNoise_ST;
    float4 _WaveTex_ST;

    half3 _WaterSallowColor;
    half3 _WaterDepthColor;
    half3 _WaterSubsurfaceColor;
    float _WaterDepthThreshold;
    float _WaterSubsurfaceThreshold;
    float _Roughness;
    float _FresnelF0;
    float _FlowDirection;
    float _FlowSpeed;
    
    float _RefractionDisturb;
    float _ReflectionDisturb;
    float _WavesDisturb;
    float _DisturbSpeed;

    float _WaveRange;
    float _WaveSpeed;
CBUFFER_END

struct PerMaterial
{
    half3 waterSallowColor;
    half3 waterDepthColor;
    half3 waterSubsurfaceColor;
    float waterDepthThreshold;
    float waterSubsurfaceThreshold;
    float roughness;
    float fresnelF0;
    
    float refractionDisturb;
    float reflectionDisturb;
    float wavesDisturb;

    float waveRange;
};

PerMaterial GetPerMaterial()
{
    PerMaterial o;
    o.waterSallowColor = _WaterSallowColor;
    o.waterDepthColor = _WaterDepthColor;
    o.waterSubsurfaceColor = _WaterSubsurfaceColor;
    o.waterDepthThreshold = _WaterDepthThreshold;
    o.waterSubsurfaceThreshold = _WaterSubsurfaceThreshold;
    o.roughness = _Roughness;
    o.fresnelF0 = _FresnelF0;
    o.refractionDisturb = _RefractionDisturb;
    o.reflectionDisturb = _ReflectionDisturb;
    o.wavesDisturb = _WavesDisturb;

    o.waveRange = _WaveRange;

    return o;
}

float2 DecodePackedUV(uint n)
{
    uint x = n & 0xffff;
    uint y = n >> 16;

    return float2((float)x, (float)y);
}

float3 SampleNormalMap(float2 uv, bool flow = false)
{
    float2 coord = TRANSFORM_TEX(uv, _NormalMap);

    UNITY_BRANCH
    if (flow)
    {
        float2 dir = float2(cos(radians(_FlowDirection)), sin(radians(_FlowDirection)));
        coord += frac(0.01 * _Time.y * _FlowSpeed * dir);
    }
    
    return UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, coord));
}

half3 SampleDisturbNoiseTexture(float2 uv, bool flow = false)
{
    float2 coord = TRANSFORM_TEX(uv, _DisturbNoise);
    coord.x += lerp(0.0, frac(0.01 * _Time.y * _DisturbSpeed), flow);
    
    return SAMPLE_TEXTURE2D(_DisturbNoise, sampler_DisturbNoise, coord).rgb;
}

half3 SampleWaveTexture(float2 uv, bool flow = false)
{
    float2 coord = TRANSFORM_TEX(uv, _WaveTex);
    coord.x += lerp(0.0, frac(0.1 * _Time.y * _WaveSpeed), flow);
    return SAMPLE_TEXTURE2D(_WaveTex, sampler_WaveTex, coord).rgb;
}

float2 SampleUVMappingTexture(float2 screenPosition)
{
#if defined(_CS_SYNC_MAPPING)
    uint n = _UVSyncMappingTexture[(uint2)screenPosition].x;
    return DecodePackedUV(n);
#else
    return _UVMappingTexture[(uint2)screenPosition].xy;
#endif
}

float SampleDepthTexture(float2 uv)
{
    return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
}

half3 SampleOpaqueTexture(float2 uv)
{
    return SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv).rgb;
}

#endif
