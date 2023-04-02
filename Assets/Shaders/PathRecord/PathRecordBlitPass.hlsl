#ifndef PATH_RECORD_BLIT_PASS_INCLUDED
#define PATH_RECORD_BLIT_PASS_INCLUDED

#include "Assets/Shaders/ShaderLibrary/Utility.hlsl"

TEXTURE2D(_SourceRecordTexture);
SAMPLER(sampler_SourceRecordTexture);
TEXTURE2D(_CurrentRecordTexture);
SAMPLER(sampler_CurrentRecordTexture);

struct Attributes
{
    float4 positionOS : POSITION;
    float2 screenUV : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 screenUV : TEXCOORD0;
};

float3 _PreOriginalPosition;
float3 _OriginalPosition;
float _RecordDistance;
float _DeltaTime;

Varyings PathRecordBlitVertex(Attributes input)
{
    Varyings output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.screenUV = input.screenUV;

    return output;
}

half4 PathRecordBlitFragment(Varyings input) : SV_Target
{
    float2 bias = (_OriginalPosition.xz - _PreOriginalPosition.xz) / _RecordDistance * 0.5;
    float2 center = input.screenUV + bias;

    input.screenUV.y = 1.0 - input.screenUV.y;

    UNITY_BRANCH
    if (center.x > 1.0 || center.x < 0.0 || center.y > 1.0 || center.y < 0.0)
    {
        return half4(0.0, 0.0, 0.0, 1.0);
    }

    float3 current = SAMPLE_TEXTURE2D(_CurrentRecordTexture, sampler_CurrentRecordTexture, input.screenUV);

    float offset = 0.0005 / _RecordDistance;
    float2 offsets[9] = {
        float2(-offset, -offset), float2(0.0, -offset), float2(offset, -offset),
        float2(-offset, 0.0),     float2(0.0, 0.0),     float2(offset, 0.0),
        float2(-offset, offset),  float2(0.0, offset),  float2(offset, offset)
    };

    float3 source = 0.0;

    UNITY_UNROLL
    for (int i = 0; i < 9; ++i)
    {
        half3 sample = SAMPLE_TEXTURE2D(_SourceRecordTexture, sampler_SourceRecordTexture, center + offsets[i]);
        sample = max(0.0, sample - _DeltaTime * 0.11);
        source += sample;
    }
    source /= 9.0;

    return half4(max(source, current), 1.0);
}

#endif
