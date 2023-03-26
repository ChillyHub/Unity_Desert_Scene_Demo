#ifndef UNIVERSAL_POSTPROCESSING_FOG_INCLUDED
#define UNIVERSAL_POSTPROCESSING_FOG_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


CBUFFER_START(UnityPerMaterial)
    half3 _FogColor;
    float _Density;

    float _HeightFogStart;
    float _HeightFogDensity;
    
    float _DistanceFogMaxLength;
    float _DistanceFogDensity;
    
    half3 _DayScatteringColor;
    half3 _NightScatteringColor;
    float _Scattering;
    float _ScatteringRedWave;
    float _ScatteringGreenWave;
    float _ScatteringBlueWave;
    float _ScatteringMoon;
    float _ScatteringFogDensity;
     
    float _DayScatteringFac;
    float _NightScatteringFac;
    float _gDayMie;
    float _gNightMie;
CBUFFER_END

struct FogData
{
    half3 fogColor;
    float density;
    float heightFogStart;
    float heightFogDensity;
    float distanceFogMaxLength;
    float distanceFogDensity;
    half3 dayScatteringColor;
    half3 nightScatteringColor;
    float scattering;
    float scatteringRedWave;
    float scatteringGreenWave;
    float scatteringBlueWave;
    float scatteringMoon;
    float scatteringFogDensity;
    float dayScatteringFac;
    float nightScatteringFac;
    float gDayMie;
    float gNightMie;
};

FogData GetFogData()
{
    FogData o;
    o.fogColor = _FogColor;
    o.density = _Density;
    o.heightFogStart = _HeightFogStart;
    o.heightFogDensity = _HeightFogDensity;
    o.distanceFogMaxLength = _DistanceFogMaxLength;
    o.distanceFogDensity = _DistanceFogDensity;
    o.dayScatteringColor = _DayScatteringColor;
    o.nightScatteringColor = _NightScatteringColor;
    o.scattering = _Scattering;
    o.scatteringRedWave = _ScatteringRedWave;
    o.scatteringGreenWave = _ScatteringGreenWave;
    o.scatteringBlueWave = _ScatteringBlueWave;
    o.scatteringMoon = _ScatteringMoon;
    o.scatteringFogDensity = _ScatteringFogDensity;
    o.dayScatteringFac = _DayScatteringFac;
    o.nightScatteringFac = _NightScatteringFac;
    o.gDayMie = _gDayMie;
    o.gNightMie = _gNightMie;

    return o;
}

float GetMiePhaseFunction(float cosTheta, float g)
{
    float g2 = g * g;
    float cos2 = cosTheta * cosTheta;
    float num = 3.0 * (1.0 - g2) * (1.0 + cos2);
    float denom = rcp(8.0 * PI * (2.0 + g2) * pow(abs(1.0 + g2 - 2.0 * g * cosTheta), 1.5));
    return num * denom;
}

half3 GetTransmitColor(FogData fd, half3 sourceColor, float len)
{
    return exp(-pow(abs(fd.scattering), 10.0) * len) * sourceColor;
}

half3 GetHeightFogColor(FogData fd, float3 positionWS, float3 viewPosWS)
{
    return fd.heightFogDensity *
        smoothstep(0.0, abs(viewPosWS.y - fd.heightFogStart), viewPosWS.y - positionWS.y) * fd.fogColor;
}

half3 GetDistanceFogColor(FogData fd, float len)
{
    return fd.distanceFogDensity * smoothstep(0.0, fd.distanceFogMaxLength, len) * fd.fogColor;
}

half3 GetScatteringFogColor(FogData fd, float3 sunDir, float3 moonDir, float3 viewDir, float len)
{
    float sunCos = dot(viewDir, sunDir);
    float moonCos = dot(viewDir, moonDir);
    float sunMiePhase = GetMiePhaseFunction(sunCos, fd.gDayMie);
    float moonMiePhase = GetMiePhaseFunction(moonCos, fd.gNightMie);
    float3 coefSun = pow(
        abs(float3(fd.scatteringRedWave, fd.scatteringGreenWave, fd.scatteringBlueWave) * fd.scattering), 10.0);
    float3 coefMoon = pow(abs(fd.scatteringMoon), 10.0);
    half3 sunScattering = sunMiePhase * fd.dayScatteringColor * (1.0 - exp(-coefSun * len));
    half3 moonScattering = moonMiePhase * fd.nightScatteringColor * (1.0 - exp(-coefMoon * len));

    return fd.scatteringFogDensity * (fd.dayScatteringFac * sunScattering + fd.nightScatteringFac * moonScattering);
}

half3 GetFogColor(FogData fd, float3 sourceColor, float3 sunDirWS, float3 moonDirWS, float3 viewDirWS,
    float3 positionWS, float3 viewPosWS)
{
    // TODO: Transmit Color
    float len = length(positionWS - viewPosWS);
    half3 excintion = GetTransmitColor(fd, sourceColor, len);
    
    // TODO: Get Height Fog Color
    half3 heightFog = GetHeightFogColor(fd, positionWS, viewPosWS);

    // TODO: Get Distance Fog Color
    half3 distanceFog = GetDistanceFogColor(fd, len);

    // TODO: Get Scattering Fog Color
    half3 inScattering = GetScatteringFogColor(fd, sunDirWS, moonDirWS, viewDirWS, len);

    return fd.density * (excintion + heightFog + distanceFog + inScattering);
}

half3 GetFogColor(FogData fd, float3 sourceColor, float3 sunDirWS, float3 moonDirWS,
    float2 positionNDC, float deviceDepth)
{
    float3 positioWS = ComputeWorldSpacePosition(positionNDC, deviceDepth, unity_MatrixInvVP);
    float3 viewPosWS = GetCameraPositionWS();
    float3 viewDirWS = normalize(viewPosWS - positioWS);

    return GetFogColor(fd, sourceColor, sunDirWS, moonDirWS, viewDirWS, positioWS, viewPosWS);
}

#endif