#ifndef PLANAR_WATER_FORWARD_PASS_INCLUDED
#define PLANAR_WATER_FORWARD_PASS_INCLUDED

#include "Assets/Shaders/ShaderLibrary/Utility.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 baseUV : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 positionVS : TEXCOORD1;
    float4 positionNDC : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float3 tangentWS : TEXCOORD4;
    float3 bitangentWS : TEXCOORD5;
    float2 baseUV : TEXCOORD6;
    UNITY_VERTEX_OUTPUT_STEREO
};

struct Surface
{
    float4 positionCS;
    float3 positionWS;
    float3 positionVS;
    float4 positionNDC;
    float3 normalWS;
    float3 bumpWS;
    float3 lightColor;
    float3 lightDirWS;
    float3 viewDirWS;
    float3 normalReflectDirWS;
    float3 bumpReflectDirWS;
    float3 refractDirWS;
    float3 fresnelTerm;

    float2 baseUV;
    float2 screenUV;
    float2 screenPosition;
    
    float posDeviceDepth;
    float mapDeviceDepth;
    float roughness;
};

Surface GetSurface(Varyings i, PerMaterial pm)
{
    Surface o;
    o.positionCS = i.positionCS;
    o.positionWS = i.positionWS;
    o.positionVS = i.positionVS;
    o.positionNDC = i.positionNDC;
    o.normalWS = i.normalWS;

    float3 normalTS = SampleNormalMap(i.baseUV, true);
    o.bumpWS = mul(normalTS, float3x3(i.tangentWS, i.bitangentWS, i.normalWS));

    Light light = GetMainLight();
    o.lightColor = light.color;
    o.lightDirWS = light.direction;
    o.viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);
    o.normalReflectDirWS = reflect(-o.viewDirWS, o.normalWS);
    o.bumpReflectDirWS = reflect(-o.viewDirWS, o.bumpWS);
    o.refractDirWS = -o.viewDirWS;

    o.baseUV = i.baseUV;
    o.screenUV = GetNormalizedScreenSpaceUV(o.positionCS);
    o.screenPosition = o.positionCS.xy;

    half3 f0 = half3(pm.fresnelF0, pm.fresnelF0, pm.fresnelF0);
    o.fresnelTerm = f0 + (1.0 - f0) * pow(1.0 - saturate(dot(o.normalWS, o.viewDirWS)), 5.0);
    o.posDeviceDepth = i.positionNDC.z / i.positionNDC.w;
    o.mapDeviceDepth = SampleDepthTexture(o.screenUV);

    o.roughness = pm.roughness;

    return o;
}

float GetSDFMask(float2 uv)
{
    float2 range = abs(uv * 2.0 - 1.0);
    float mask = smoothstep(0.0, 0.2, (1.0 - range.x) * (1.0 - range.y));
    return mask;
}

half3 GetRefractionColor(PerMaterial pm, Surface surface, out half alpha)
{
    float mapDepth = LinearEyeDepth(surface.mapDeviceDepth, _ZBufferParams);
    float posDepth = LinearEyeDepth(surface.posDeviceDepth, _ZBufferParams);
    
    // TODO: Disturb
    half noise = SampleDisturbNoiseTexture(surface.screenUV, true).r;
    half bias = (noise - 0.5) * pm.refractionDisturb;
    half2 biasUV = surface.screenUV + float2(bias, 0.0);

    float biasMapDeviceDepth = SampleDepthTexture(biasUV);
    float biasMapDepth = LinearEyeDepth(biasMapDeviceDepth, _ZBufferParams);

    bias *= saturate(biasMapDepth - posDepth);
    biasUV = surface.screenUV + float2(bias, 0.0);
    biasMapDeviceDepth = SampleDepthTexture(biasUV);
    biasMapDepth = LinearEyeDepth(biasMapDeviceDepth, _ZBufferParams);
    
    half3 baseColor = SampleOpaqueTexture(biasUV);

    half fac = lerp(mapDepth - posDepth, biasMapDepth - posDepth, step(0, biasMapDepth - posDepth));
    half3 waterColor = lerp(baseColor * pm.waterSallowColor, pm.waterDepthColor,
        smoothstep(0.0, pm.waterDepthThreshold, fac));

    alpha = saturate(smoothstep(0.0, 0.5, mapDepth - posDepth));

    // TODO: Subsurface Scattering
    waterColor += pm.waterSubsurfaceColor * smoothstep(0.0, pm.waterSubsurfaceThreshold, fac);
    
    return waterColor;
}

half3 GetReflectionColor(PerMaterial pm, Surface surface)
{
    // TODO: Disturb Color
    half noise = SampleDisturbNoiseTexture(surface.screenUV, true).g;
    half bias = (noise - 0.5) * pm.reflectionDisturb;
    half2 biasUV = surface.screenUV + float2(bias, 0.0);

    float biasMapDeviceDepth = SampleDepthTexture(biasUV);
    float biasMapDepth = LinearEyeDepth(biasMapDeviceDepth, _ZBufferParams);

    bias *= saturate(biasMapDepth - LinearEyeDepth(surface.posDeviceDepth, _ZBufferParams) * 0.1);
    biasUV = surface.screenUV + float2(bias, 0.0);

    float2 biasReflectUV = SampleUVMappingTexture(clamp(0.0, 1.0, biasUV));
    
    half3 reflectColor = SampleOpaqueTexture(biasReflectUV);

    // TODO: Blur and sample skybox outside mask
    float mask = GetSDFMask(biasReflectUV);
    half3 skybox = GlossyEnvironmentReflection(surface.bumpReflectDirWS, 0.0h, 1.0h);
    reflectColor = lerp(skybox, reflectColor, mask);

    BRDFData brdf = (BRDFData)0;
    brdf.roughness = surface.roughness;
    brdf.roughness2 = brdf.roughness * brdf.roughness;
    brdf.roughness2MinusOne = brdf.roughness2 - 1.0;
    brdf.normalizationTerm = brdf.roughness * 4.0 + 2.0;
    half3 specular = DirectBRDFSpecular(brdf, surface.bumpWS, surface.lightDirWS, surface.viewDirWS);
    reflectColor += specular * surface.lightColor;

    return reflectColor;
}

half4 DrawWave(PerMaterial pm, Surface surface)
{
    float mapDepth = LinearEyeDepth(surface.mapDeviceDepth, _ZBufferParams);
    float posDepth = LinearEyeDepth(surface.posDeviceDepth, _ZBufferParams);
    half waveV = surface.baseUV.x + surface.baseUV.y;
    half waveU = smoothstep(0.0, pm.waveRange, mapDepth - posDepth);
    half3 color = SampleWaveTexture(float2(waveU, waveV), true) * (1.0 - waveU);
    return half4(color * 2.0, color.r);
}

Varyings PlanarWaterPassVertex(Attributes input)
{
    VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    output.positionCS = positionInput.positionCS;
    output.positionWS = positionInput.positionWS;
    output.positionVS = positionInput.positionVS;
    output.positionNDC = positionInput.positionNDC;
    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;
    output.baseUV = input.baseUV;

    return output;
}

half4 PlanarWaterPassFragment(Varyings input) : SV_Target
{
    // TODO: Init Data
    PerMaterial pm = GetPerMaterial();
    Surface surface = GetSurface(input, pm);

    // TODO: Get Refraction Color
    //       Sample Color Map and Add water color
    //       Add SSS, Add Disturbance
    half alpha;
    half3 refraction = GetRefractionColor(pm, surface, alpha);

    // TODO: Get Reflection Color
    //       Use SSPR, and sample skybox
    //       Add specular
    half3 reflection = GetReflectionColor(pm, surface);

    // TODO: Refraction or Reflection (By Fresnel)
    half3 color = lerp(refraction, reflection, surface.fresnelTerm);

    // TODO: Add Wave
    half4 wave = DrawWave(pm, surface);
    //alpha = max(alpha, wave.a);

    return half4(color + wave, alpha);
}

#endif
