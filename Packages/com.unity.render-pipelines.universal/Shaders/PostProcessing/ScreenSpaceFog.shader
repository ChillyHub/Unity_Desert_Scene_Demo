Shader "Hidden/Universal Render Pipeline/Custom/Screen Space Fog" 
{
	SubShader 
	{
		Cull Off 
		ZWrite Off 
		ZTest Always

		Pass
		{
			Name "Screen Space Fog Pass"
			
			HLSLPROGRAM

			#pragma target 4.5

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT
			
			#pragma vertex ScreenSpaceFogPassVertex
			#pragma fragment ScreenSpaceFogPassFragment
			
			#include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/ScreenSpaceFogPass.hlsl"

			ENDHLSL
		}
	}
}