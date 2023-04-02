Shader "Hidden/Custom/Path Record Blit"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			Name "Path Record Blit Pass"
			
			Cull Off 
			ZWrite Off 
			ZTest Always
			
			HLSLPROGRAM

			#pragma target 4.5

			#pragma vertex PathRecordBlitVertex
			#pragma fragment PathRecordBlitFragment

			#include "Assets/Shaders/PathRecord/PathRecordBlitPass.hlsl"
			
			ENDHLSL
		}
	}
}