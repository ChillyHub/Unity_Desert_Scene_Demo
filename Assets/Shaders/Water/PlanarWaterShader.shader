Shader "Custom/Water/Planat Water"
{
	Properties
	{
		[Header(Color Setting)][Space]
		_WaterSallowColor("Water Shallow Color", Color) = (0.6, 0.7, 0.8)
		_WaterDepthColor("Water Depth Color", Color) = (0.2, 0.4, 0.9)
		_WaterSubsurfaceColor("Water Subsurface Color", Color) = (0.4, 0.8, 0.5)
		_WaterDepthThreshold("Water Depth Threshold", Range(0.0, 10.0)) = 3.0
		_WaterSubsurfaceThreshold("Water Subsurface Threshold", Range(0.0, 10.0)) = 1.0
		
		[Header(Surface Setting)][Space]
		_NormalMap("Normal Map", 2D) = "bump" {}
		_DisturbNoise("Disturb Noise Texture", 2D) = "gray" {}
		_WaveTex("Water Wave Tex", 2D) = "black" {}
		_Roughness("Surface Roughness", Range(0.0, 0.1)) = 0.01
		_FresnelF0("Fresnel F0", Range(0.0, 0.5)) = 0.03
		_FlowDirection("Flow Direction", Range(0.0, 360.0)) = 0.0
		_FlowSpeed("Flow Speed", Range(0.0, 2.0)) = 1.0
		
		[Header(Disturb Setting)][Space]
		_RefractionDisturb("Refraction Disturb", Range(0.0, 1.0)) = 0.5
		_ReflectionDisturb("Reflection Disturb", Range(0.0, 1.0)) = 0.5
		_WavesDisturb("Waves Disturb", Range(0.0, 1.0)) = 0.5
		_DisturbSpeed("Disturb Speed", Range(0.0, 2.0)) = 1.0
		
		[Header(Wave Setting)][Space]
		_WaveRange("Wave Range", Range(0.0, 5.0)) = 0.5
		_WaveSpeed("Wave Speed", Range(0.0, 2.0)) = 1.0
		
		[Header(Blend Mode)][Space]
        // Set blend mode
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		// Default write into depth buffer
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
        // Alpha test
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping("Alpha Clipping", Float) = 0
        // Alpha premultiply
		[Toggle(_PREMULTIPLY_ALPHA)] _PreMulAlphaToggle("Alpha premultiply", Float) = 0
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
		
		Cull back
		Blend [_SrcBlend] [_DstBlend], One OneMinusSrcAlpha
		ZWrite [_ZWrite]

		Pass
		{
			Name "Planar Water Pass"
			Tags { "LightMode"="UniversalForward" }
			
			HLSLPROGRAM

			#pragma target 4.5

			#pragma shader_feature _CS_SYNC_MAPPING
			
			#pragma vertex PlanarWaterPassVertex
			#pragma fragment PlanarWaterPassFragment

			#include "Assets/Shaders/Water/PlanarWaterInput.hlsl"
			#include "Assets/Shaders/Water/PlanarWaterForwardPass.hlsl"
			
			ENDHLSL
		}
	}
}
