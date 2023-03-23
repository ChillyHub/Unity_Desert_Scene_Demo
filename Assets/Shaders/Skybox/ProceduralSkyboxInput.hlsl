#ifndef PROCEDURAL_SKYBOX_INPUT_INCLUDED
#define PROCEDURAL_SKYBOX_INPUT_INCLUDED

#include "Assets/Shaders/ShaderLibrary/Utility.hlsl"

TEXTURE2D(_MoonDiffuse);
SAMPLER(sampler_MoonDiffuse);
TEXTURE2D(_MoonAlpha);
SAMPLER(sampler_MoonAlpha);
TEXTURE2D(_CloudsAtlas);
SAMPLER(sampler_CloudsAtlas);

CBUFFER_START(UnityPerMaterial)
    half3 _SunColor;
    half3 _DayColor;
    half3 _HorizDayColor;
    half3 _NightColor;
    half3 _HorizNightColor;
    half3 _MoonColor;
    float _Scattering;
    float _ScatteringRedWave;
    float _ScatteringGreenWave;
    float _ScatteringBlueWave;
    float _Exposure;
    
    float _dayScatteringFac;
    float _nightScatteringFac;
    float _gDayMie;
    float _gNightMie;
    float _gSun;

    float _SkyTime;
CBUFFER_END

const static float sThickness = 10000.0;
const static float sRadius = 85000.0;

struct PerMaterial
{
    half3 sunColor;
    half3 dayColor;
    half3 horizDayColor;
    half3 nightColor;
    half3 horizNightColor;
    half3 moonColor;
    float scattering;
    float scatteringRedWave;
    float scatteringGreenWave;
    float scatteringBlueWave;
    float exposure;
    
    float dayScatteringFac;
    float nightScatteringFac;
    float gDayMie;
    float gNightMie;
    float gSun;

    float thickness;
    float radius;

    float skyTime;
    float isMoon;
};

PerMaterial GetPerMaterial()
{
    PerMaterial o;
    o.sunColor = _SunColor;
    o.dayColor = _DayColor;
    o.horizDayColor = _HorizDayColor;
    o.nightColor = _NightColor;
    o.horizNightColor = _HorizNightColor;
    o.moonColor = _MoonColor;
    o.scattering = _Scattering;
    o.scatteringRedWave = _ScatteringRedWave;
    o.scatteringGreenWave = _ScatteringGreenWave;
    o.scatteringBlueWave = _ScatteringBlueWave;
    o.exposure = _Exposure;
    
    o.dayScatteringFac = _dayScatteringFac;
    o.nightScatteringFac = _nightScatteringFac;
    o.gDayMie = _gDayMie;
    o.gNightMie = _gNightMie;
    o.gSun = _gSun;

    o.thickness = sThickness;
    o.radius = sRadius;

    o.skyTime = _SkyTime;
    o.isMoon = 0.0;

    return o;
}

half3 SampleMoonDiffuseTexture(float2 uv)
{
    return SAMPLE_TEXTURE2D(_MoonDiffuse, sampler_MoonDiffuse, uv).aaa;
}

half SampleMoonAlphaTexture(float2 uv)
{
    return SAMPLE_TEXTURE2D(_MoonAlpha, sampler_MoonAlpha, uv).a;
}

#endif