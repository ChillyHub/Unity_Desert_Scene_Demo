#ifndef DESERT_TERRAIN_TESSELATION_LIT_PASS_INCLUDED
#define DESERT_TERRAIN_TESSELATION_LIT_PASS_INCLUDED

#include "Assets/Shaders/Terrain/DesertTerrainLitPass.hlsl"

struct VertexIn
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOut
{
    float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap
    #ifndef TERRAIN_SPLAT_BASEPASS
    float4 uvSplat01                : TEXCOORD1; // xy: splat0, zw: splat1
    float4 uvSplat23                : TEXCOORD2; // xy: splat2, zw: splat3
    #endif

    #if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    half4 normal                    : TEXCOORD3;    // xyz: normal, w: viewDir.x
    half4 tangent                   : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    half4 bitangent                 : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
    #else
    half3 normal                    : TEXCOORD3;
    half3 vertexSH                  : TEXCOORD4; // SH
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
    #else
    half  fogFactor                 : TEXCOORD6;
    #endif

    float3 positionWS               : TEXCOORD7;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD8;
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
    float2 dynamicLightmapUV        : TEXCOORD9;
    #endif

    UNITY_VERTEX_OUTPUT_STEREO
};

struct HullOut
{
    float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap
    #ifndef TERRAIN_SPLAT_BASEPASS
    float4 uvSplat01                : TEXCOORD1; // xy: splat0, zw: splat1
    float4 uvSplat23                : TEXCOORD2; // xy: splat2, zw: splat3
    #endif

    #if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    half4 normal                    : TEXCOORD3;    // xyz: normal, w: viewDir.x
    half4 tangent                   : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    half4 bitangent                 : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
    #else
    half3 normal                    : TEXCOORD3;
    half3 vertexSH                  : TEXCOORD4; // SH
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
    #else
    half  fogFactor                 : TEXCOORD6;
    #endif

    float3 positionWS               : TEXCOORD7;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD8;
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
    float2 dynamicLightmapUV        : TEXCOORD9;
    #endif

    UNITY_VERTEX_OUTPUT_STEREO
};

#define INTERPOLATE(outputPatch, weight, fieldName) \
    outputPatch[0].fieldName * weight.x + \
    outputPatch[1].fieldName * weight.y + \
    outputPatch[2].fieldName * weight.z

struct PatchTess
{
    float EdgeTess[3] : SV_TessFactor;
    float InsideTess : SV_InsideTessFactor;
};

PatchTess ConstantHS(InputPatch<VertexOut, 3> patch, uint patchID : SV_PrimitiveID)
{
    float3 centerWS = (patch[0].positionWS + patch[1].positionWS + patch[2].positionWS) / 3.0f;

    const float near = 5.0f;
    const float far = 20.0f;
    float dist = distance(GetCameraPositionWS(), centerWS);
    float tess = 32.0f * clamp((far - dist) / (far - near), 0.01f, 1.0f);
    
    PatchTess pt;
    pt.EdgeTess[0] = tess;
    pt.EdgeTess[1] = tess;
    pt.EdgeTess[2] = tess;
    pt.InsideTess = tess;

    return pt;
}

float GetHeight(float2 uv)
{
    // Depth
    float s = 0.0;
    if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0)
    {
        s = SAMPLE_TEXTURE2D_LOD(_PathRecordTexture, sampler_PathRecordTexture, uv, 0);
    }

    // Edge
    float offset = 0.001 / _RecordDistance;
    float2 sobelXOffsets[6] = {
        float2(-offset, -offset), float2(-offset, 0.0), float2(-offset, offset),
        float2(offset, -offset),  float2(offset, 0.0),  float2(offset, offset)
    };
    float2 sobelYOffsets[6] = {
        float2(-offset, -offset), float2(0.0, -offset), float2(offset, -offset),
        float2(-offset, offset),  float2(0.0, offset),  float2(offset, offset)
    };
    float sobelValue[6] = { -1.0, -2.0, -1.0, 1.0, 2.0, 1.0 };

    float gx = 0.0;
    float gy = 0.0;
    UNITY_UNROLL
    for (int i = 0; i < 6; ++i)
    {
        float sampleX = 0.0;
        float sampleY = 0.0;
        float2 uvX = uv + sobelXOffsets[i];
        float2 uvY = uv + sobelYOffsets[i];
        if (uvX.x > 0.0 && uvX.x < 1.0 && uvX.y > 0.0 && uvX.y < 1.0)
        {
            sampleX = SAMPLE_TEXTURE2D_LOD(_PathRecordTexture, sampler_PathRecordTexture, uv + sobelXOffsets[i], 0);
        }
        if (uvY.x > 0.0 && uvY.x < 1.0 && uvY.y > 0.0 && uvY.y < 1.0)
        {
            sampleY = SAMPLE_TEXTURE2D_LOD(_PathRecordTexture, sampler_PathRecordTexture, uv + sobelYOffsets[i], 0);
        }
        gx += sampleX * sobelValue[i];
        gy += sampleY * sobelValue[i];
    }

    float g = sqrt(gx * gx + gy * gy);
    
    float down = lerp(0.0, 0.1, saturate(s));
    float up = lerp(0.0, 0.3, saturate(g));
    float height = lerp(up, -down, saturate(s));

    return height * _HeightVaryings;
}

///////////////////////////////////////////////////////////////////////////////
//        Tesselation Vertex, Hull, Domain and Fragment functions            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard Terrain shader
VertexOut TessSplatmapVert(VertexIn v)
{
    VertexOut o = (VertexOut)0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    TerrainInstancing(v.positionOS, v.normalOS, v.texcoord);

    VertexPositionInputs Attributes = GetVertexPositionInputs(v.positionOS.xyz);

    o.uvMainAndLM.xy = v.texcoord;
    o.uvMainAndLM.zw = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;

    #ifndef TERRAIN_SPLAT_BASEPASS
        o.uvSplat01.xy = TRANSFORM_TEX(v.texcoord, _Splat0);
        o.uvSplat01.zw = TRANSFORM_TEX(v.texcoord, _Splat1);
        o.uvSplat23.xy = TRANSFORM_TEX(v.texcoord, _Splat2);
        o.uvSplat23.zw = TRANSFORM_TEX(v.texcoord, _Splat3);
    #endif

#if defined(DYNAMICLIGHTMAP_ON)
    o.dynamicLightmapUV = v.texcoord * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

    #if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(Attributes.positionWS);
        float4 vertexTangent = float4(cross(float3(0, 0, 1), v.normalOS), 1.0);
        VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, vertexTangent);

        o.normal = half4(normalInput.normalWS, viewDirWS.x);
        o.tangent = half4(normalInput.tangentWS, viewDirWS.y);
        o.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);
    #else
        o.normal = TransformObjectToWorldNormal(v.normalOS);
        o.vertexSH = SampleSH(o.normal);
    #endif

    half fogFactor = 0;
    #if !defined(_FOG_FRAGMENT)
        fogFactor = ComputeFogFactor(Attributes.positionCS.z);
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        o.fogFactorAndVertexLight.x = fogFactor;
        o.fogFactorAndVertexLight.yzw = VertexLighting(Attributes.positionWS, o.normal.xyz);
    #else
        o.fogFactor = fogFactor;
    #endif

    o.positionWS = Attributes.positionWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        o.shadowCoord = GetShadowCoord(Attributes);
    #endif

    return o;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("ConstantHS")]
[maxtessfactor(64.0f)]
HullOut TessSplatmapHull(InputPatch<VertexOut, 3> patch, uint i : SV_OutputControlPointID, uint patchID : SV_PrimitiveID)
{
    HullOut output;
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(patch[i], output);
    output.uvMainAndLM = patch[i].uvMainAndLM;
    #ifndef _TERRAIN_SPLAT_BASEPASS
    output.uvSplat01 = patch[i].uvSplat01;
    output.uvSplat23 = patch[i].uvSplat23;
    #endif

    #if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    output.normal = patch[i].normal;
    output.tangent = patch[i].tangent;
    output.bitangent = patch[i].bitangent;
    #else
    output.normal = patch[i].normal;
    output.vertexSH = patch[i].vertexSH;
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    output.fogFactorAndVertexLight = patch[i].fogFactorAndVertexLight;
    #else
    output.fogFactor = patch[i].fogFactor;
    #endif

    output.positionWS = patch[i].positionWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = patch[i].shadowCoord;
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
    output.dynamicLightmapUV = patch[i].dynamicLightmapUV;
    #endif

    return output;
}

[domain("tri")]
Varyings TessSplatmapDomain(PatchTess patchTess, float3 w : SV_DomainLocation, const OutputPatch<HullOut, 3> tri)
{
    Varyings output;
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(patch[i], output);
    output.uvMainAndLM = INTERPOLATE(tri, w, uvMainAndLM);
    #ifndef _TERRAIN_SPLAT_BASEPASS
    output.uvSplat01 = INTERPOLATE(tri, w, uvSplat01);
    output.uvSplat23 = INTERPOLATE(tri, w, uvSplat23);
    #endif

    #if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    output.normal = INTERPOLATE(tri, w, normal);
    output.tangent = INTERPOLATE(tri, w, tangent);
    output.bitangent = INTERPOLATE(tri, w, bitangent);
    #else
    output.normal = INTERPOLATE(tri, w, normal);
    output.vertexSH = INTERPOLATE(tri, w, vertexSH);
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    output.fogFactorAndVertexLight = INTERPOLATE(tri, w, fogFactorAndVertexLight);
    #else
    output.fogFactor = INTERPOLATE(tri, w, fogFactor);
    #endif

    output.positionWS = INTERPOLATE(tri, w, positionWS);

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = INTERPOLATE(tri, w, shadowCoord);
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
    output.dynamicLightmapUV = INTERPOLATE(tri, w, dynamicLightmapUV);
    #endif

    float offset = 0.03 / _RecordDistance;
    float2 uv = (output.positionWS.xz - _OriginalPosition.xz) / _RecordDistance * 0.5 + 0.5;
    float2 uvdx = uv + float2(offset, 0.0);
    float2 uvdy = uv + float2(0.0, offset);

    #if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    float h = GetHeight(uv);
    float dhdx = (GetHeight(uvdx) - h) / offset * 0.5;
    float dhdy = (GetHeight(uvdy) - h) / offset * 0.5;

    float3 normalTS = normalize(float3(dhdx, dhdy, 1.0));

    // Displace
    output.positionWS += output.normal * h;
    output.normal.xyz = mul(normalTS, float3x3(output.tangent.xyz, -output.bitangent.xyz, output.normal.xyz));

    float3 viewPos = GetCameraPositionWS();
    float3 viewDir = normalize(viewPos - output.positionWS);
    output.normal.w = viewDir.x;
    output.tangent.w = viewDir.y;
    output.bitangent.w = viewDir.z;
    #else
    float h = GetHeight(uv);
    float hx = GetHeight(uvdx);
    float hy = GetHeight(uvdy);
    float3 positionWS = output.positionWS + output.normal * h;
    float3 positionWSox = output.positionWS + output.normal * hx;
    float3 positionWSoy = output.positionWS + output.normal * hy;
    float dhdx = (positionWSox - positionWS) / offset;
    float dhdy = (positionWSoy - positionWS) / offset;

    output.positionWS = positionWS;
    output.normal.xyz = normalize(float3(dhdx, dhdy, 1.0));
    #endif

    output.clipPos = TransformWorldToHClip(output.positionWS);
    return output;
}

#ifdef TERRAIN_GBUFFER
FragmentOutput TessSplatmapFragment(Varyings IN)
#else
half4 TessSplatmapFragment(Varyings IN) : SV_TARGET
#endif
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
#ifdef _ALPHATEST_ON
    ClipHoles(IN.uvMainAndLM.xy);
#endif

    half3 normalTS = half3(0.0h, 0.0h, 1.0h);
#ifdef TERRAIN_SPLAT_BASEPASS
    half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uvMainAndLM.xy).rgb;
    half smoothness = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uvMainAndLM.xy).a;
    half metallic = SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, IN.uvMainAndLM.xy).r;
    half alpha = 1;
    half occlusion = 1;
#else

    half4 hasMask = half4(_LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3);
    half4 masks[4];
    ComputeMasks(masks, hasMask, IN);

    float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
    half4 splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);

    half alpha = dot(splatControl, 1.0h);
#ifdef _TERRAIN_BLEND_HEIGHT
    // disable Height Based blend when there are more than 4 layers (multi-pass breaks the normalization)
    if (_NumLayersCount <= 4)
        HeightBasedSplatModify(splatControl, masks);
#endif

    half weight;
    half4 mixedDiffuse;
    half4 defaultSmoothness;
    float3 screenUV = float3(GetNormalizedScreenSpaceUV(IN.clipPos), Linear01Depth(IN.clipPos.z, _ZBufferParams));
    SplatmapMix(IN.uvMainAndLM, IN.uvSplat01, IN.uvSplat23, screenUV, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
    half3 albedo = mixedDiffuse.rgb;

    half4 defaultMetallic = half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3);
    half4 defaultOcclusion = half4(_MaskMapRemapScale0.g, _MaskMapRemapScale1.g, _MaskMapRemapScale2.g, _MaskMapRemapScale3.g) +
                            half4(_MaskMapRemapOffset0.g, _MaskMapRemapOffset1.g, _MaskMapRemapOffset2.g, _MaskMapRemapOffset3.g);

    half4 maskSmoothness = half4(masks[0].a, masks[1].a, masks[2].a, masks[3].a);
    defaultSmoothness = lerp(defaultSmoothness, maskSmoothness, hasMask);
    half smoothness = dot(splatControl, defaultSmoothness);

    half4 maskMetallic = half4(masks[0].r, masks[1].r, masks[2].r, masks[3].r);
    defaultMetallic = lerp(defaultMetallic, maskMetallic, hasMask);
    half metallic = dot(splatControl, defaultMetallic);

    half4 maskOcclusion = half4(masks[0].g, masks[1].g, masks[2].g, masks[3].g);
    defaultOcclusion = lerp(defaultOcclusion, maskOcclusion, hasMask);
    half occlusion = dot(splatControl, defaultOcclusion);
#endif

    InputData inputData;
    InitializeInputData(IN, normalTS, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, IN.uvMainAndLM.xy, _BaseMap);

#if defined(_DBUFFER)
    half3 specular = half3(0.0h, 0.0h, 0.0h);
    ApplyDecal(IN.clipPos,
        albedo,
        specular,
        inputData.normalWS,
        metallic,
        occlusion,
        smoothness);
#endif

#ifdef TERRAIN_GBUFFER

    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, alpha, brdfData);

    // Baked lighting.
    half4 color;
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
    color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
    color.a = alpha;
    SplatmapFinalColor(color, inputData.fogCoord);

    // Dynamic lighting: emulate SplatmapFinalColor() by scaling gbuffer material properties. This will not give the same results
    // as forward renderer because we apply blending pre-lighting instead of post-lighting.
    // Blending of smoothness and normals is also not correct but close enough?
    brdfData.albedo.rgb *= alpha;
    brdfData.diffuse.rgb *= alpha;
    brdfData.specular.rgb *= alpha;
    brdfData.reflectivity *= alpha;
    inputData.normalWS = inputData.normalWS * alpha;
    smoothness *= alpha;

    return BRDFDataToGbuffer(brdfData, inputData, smoothness, color.rgb, occlusion);

#else

    half4 color = UniversalFragmentPBR(inputData, albedo, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, occlusion, /* emission */ half3(0, 0, 0), alpha);

    SplatmapFinalColor(color, inputData.fogCoord);

    return half4(color.rgb, 1.0h);
#endif
}

#endif
