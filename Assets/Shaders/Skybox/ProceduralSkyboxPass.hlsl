#ifndef PROCEDURAL_SKYBOX_PASS_INCLUDED
#define PROCEDURAL_SKYBOX_PASS_INCLUDED

#include "Assets/Shaders/ShaderLibrary/Utility.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float2 baseUV : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 viewPosWS : TEXCOORD1;
    float2 baseUV : TEXCOORD2;
    UNITY_VERTEX_OUTPUT_STEREO
};

/**
 * \brief 
 * \param tIn In sphere intersection point t
 * \param tOut Out sphere intersection point t
 * \param D Ray direction
 * \param O Ray original
 * \param C Sphere center
 * \param R Sphere radius
 */
void GetSphereIntersection(out float tIn, out float tOut, float3 D, float3 O, float3 C, float R)
{
    float3 co = O - C;
    float a = dot(D, D);
    float b = 2.0 * dot(D, co);
    float c = dot(co, co) - R * R;
    float m = sqrt(max(b * b - 4.0 * a * c, 0.0));
    float div = rcp(2.0 * a);

    tIn = (-b - m) * div;
    tOut = (-b + m) * div;
}

float GetMiePhaseFunction(float cosTheta, float g)
{
    float g2 = g * g;
    float cos2 = cosTheta * cosTheta;
    float num = 3.0 * (1.0 - g2) * (1.0 + cos2);
    float denom = rcp(8.0 * PI * (2.0 + g2) * pow(abs(1.0 + g2 - 2.0 * g * cosTheta), 1.5));
    return num * denom;
}

float3 GetBaseSkyboxColor(PerMaterial d, float3 lightDir, float2 uv)
{
    half3 dayColor = lerp(d.horizDayColor, d.dayColor, smoothstep(0.0, 0.5, abs(uv.y)));
    half3 nightColor = lerp(d.horizNightColor, d.nightColor, smoothstep(0.0, 0.5, abs(uv.y)));
    return lerp(nightColor, dayColor, smoothstep(-0.5, 0.5, dot(lightDir, float3(0.0, 1.0, 0.0))));
}

float3 GetMieScatteringColor(PerMaterial d, float3 lightDir, float3 viewDir)
{
    float tIn, tOut;
    GetSphereIntersection(tIn, tOut, lightDir, float3(0.0, 0.0, 0.0), float3(0.0, -d.radius, 0.0), d.radius);

    float len = tOut;
    float cosTheta = dot(-lightDir, viewDir);
    float gMie = lerp(d.gDayMie, d.gNightMie, d.isMoon);
    float scatteringFac = lerp(d.dayScatteringFac, d.nightScatteringFac, d.isMoon);
    float3 coef = pow(float3(d.scatteringRedWave, d.scatteringGreenWave, d.scatteringBlueWave) * d.scattering, 10.0);
    half3 scattering = d.sunColor * GetMiePhaseFunction(cosTheta, gMie) * (1.0 - exp(-coef * len));

    return scattering * scatteringFac;
}

float3 DrawSun(PerMaterial d, float3 lightDir, float3 viewDir)
{
    float visual = smoothstep(-0.01, 0.0, dot(viewDir, float3(0.0, -1.0, 0.0)));
    return d.sunColor * GetMiePhaseFunction(dot(-lightDir, viewDir), d.gSun) * visual;
}

float3 DrawMoon(PerMaterial d, float3 moonDir, float3 viewDir)
{
    float cosT = dot(-moonDir, viewDir);
    float cosC = cos(0.2);
    float sinC = sin(0.2);

    UNITY_BRANCH
    if (cosT < cosC)
    {
        return float3(0.0, 0.0, 0.0);
    }
    
    float3 rightDir = cross(-moonDir, float3(0.0, 1.0, 0.0));
    float3 upDir = cross(rightDir, -moonDir);
    float3 frontDir = cross(rightDir, upDir);

    float3x3 WToL = float3x3(rightDir, upDir, frontDir);
    float3 viewDirLS = mul(WToL, viewDir);

    float u = -asin(viewDirLS.x) / (sinC * PI);
    float v = -viewDirLS.y / sinC;
    float2 uv = float2(u, v);

    float3 color = SampleMoonDiffuseTexture(uv);
    float alpha = SampleMoonAlphaTexture(uv);
    return color * alpha;
}

float3 DrawClouds(PerMaterial d, float3 lightDir)
{
    return float3(0.0, 0.0, 0.0);
}

float3 DrawStars(PerMaterial d, float3 lightDir)
{
    return float3(0.0, 0.0, 0.0);
}

Varyings ProceduralSkyboxPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.viewPosWS = GetCameraPositionWS();
    output.baseUV = input.baseUV;

    return output;
}

float4 ProceduralSkyboxPassFragment(Varyings input) : SV_Target
{
    Light light = GetMainLight();
    PerMaterial data = GetPerMaterial();
    float3 viewDir = normalize(input.viewPosWS - input.positionWS);
    float3 lightDir = light.direction;

    // TODO: Get Base Skybox Color
    float3 base = GetBaseSkyboxColor(data, lightDir, input.baseUV);

    // TODO: Get Mie Scattering Color
    float3 mie = GetMieScatteringColor(data, lightDir, viewDir);

    // TODO: Draw Sun or Moon
    float3 sun = DrawSun(data, lightDir, viewDir);
    float3 moon = DrawMoon(data, -lightDir, viewDir);

    // TODO: Draw Clouds and Stars
    float3 cloud = DrawClouds(data, lightDir);
    float3 star = DrawStars(data, lightDir);

    return float4(min(mie + sun, 10.0) * data.exposure, 1.0);
    return float4(min(base + mie + sun + moon + cloud + star, 10.0), 1.0);
}

#endif
