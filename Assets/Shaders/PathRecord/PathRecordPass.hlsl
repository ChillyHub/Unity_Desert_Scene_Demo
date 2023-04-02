#ifndef PATH_RECORD_PASS_INCLUDED
#define PATH_RECORD_PASS_INCLUDED

#include "Assets/Shaders/ShaderLibrary/Utility.hlsl"

struct Attributes
{
    float4 positionOS     : POSITION;
    float2 baseUV         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float3 positionVS   : TEXCOORD0;
    float2 baseUV       : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

TEXTURE2D(_GroundDepthTexture);
SAMPLER(sampler_GroundDepthTexture);

// x: near // y: far // z: reverse Z // w: un use
float4 _OrthoProjectionParams;
float4 _GroundDepthTexture_TexelSize;

float GetOrthoEyeDepth(float depth, float4 orthoProjectionParams)
{
    depth = lerp(depth, 1.0 - depth, orthoProjectionParams.z);
    return orthoProjectionParams.x + (orthoProjectionParams.y - orthoProjectionParams.x) * depth;
}

Varyings PathRecordVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = vertexInput.positionCS;
    output.positionVS = vertexInput.positionVS;
    output.baseUV = input.baseUV;

    return output;
}

half4 PathRecordFragment(Varyings input) : SV_Target
{
    float2 screenUV = input.positionCS.xy * _GroundDepthTexture_TexelSize.xy;
    float depth = SAMPLE_DEPTH_TEXTURE(_GroundDepthTexture, sampler_GroundDepthTexture, screenUV);
    float mapDepthEye = GetOrthoEyeDepth(depth, _OrthoProjectionParams);
    float curDepthEye = GetOrthoEyeDepth(input.positionCS.z, _OrthoProjectionParams);
    half3 dest = smoothstep(0.0, 0.05, mapDepthEye - curDepthEye);

    return half4(dest, 1.0);
}

#endif