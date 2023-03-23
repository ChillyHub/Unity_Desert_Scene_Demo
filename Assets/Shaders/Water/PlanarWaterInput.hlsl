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
TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

CBUFFER_START(UnityPerMaterial)
    half3 _WaterSallowColor;
    half3 _WaterDepthColor;
    half3 _WaterSubsurfaceColor;
    float _WaterDepthThreshold;
    float _WaterSubsurfaceThreshold;
    
    float _RefractionDisturb;
    float _ReflectionDisturb;
    float _WavesDisturb;
CBUFFER_END

struct PerMaterial
{
    half3 waterSallowColor;
    half3 waterDepthColor;
    half3 waterSubsurfaceColor;
    float waterDepthThreshold;
    float waterSubsurfaceThreshold;
    
    float refractionDisturb;
    float reflectionDisturb;
    float wavesDisturb;
};

PerMaterial GetPerMaterial()
{
    PerMaterial o;
    o.waterSallowColor = _WaterSallowColor;
    o.waterDepthColor = _WaterDepthColor;
    o.waterSubsurfaceColor = _WaterSubsurfaceColor;
    o.waterDepthThreshold = _WaterDepthThreshold;
    o.waterSubsurfaceThreshold = _WaterSubsurfaceThreshold;
    o.refractionDisturb = _RefractionDisturb;
    o.reflectionDisturb = _ReflectionDisturb;
    o.wavesDisturb = _WavesDisturb;

    return o;
}

float2 DecodePackedUV(uint2 n)
{
    uint x = n & 0xffff;
    uint y = n >> 16;

    return float2((float)x, (float)y);
}

float3 SampleNormalMap(float2 uv)
{
    return UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv));
}

half3 SampleDisturbNoiseTexture(float2 uv)
{
    return SAMPLE_TEXTURE2D(_DisturbNoise, sampler_DisturbNoise, uv).rgb;
}

half3 SampleWaveTexture(float2 uv)
{
    return SAMPLE_TEXTURE2D(_WaveTex, sampler_WaveTex, uv).rgb;
}

float2 SampleUVMappingTexture(float2 screenPosition)
{
    uint n = _UVMappingTexture[(uint2)screenPosition].x;
    return DecodePackedUV(n);
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
