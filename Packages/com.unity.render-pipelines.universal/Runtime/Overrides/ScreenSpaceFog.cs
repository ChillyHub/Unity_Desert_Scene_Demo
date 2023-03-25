using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Rendering.Universal
{
    [Serializable]
    [VolumeComponentMenuForRenderPipeline("Post-processing/Screen Space Fog", typeof(UniversalRenderPipeline))]
    public class ScreenSpaceFog : VolumeComponent, IPostProcessComponent
    {
        [Header("Base Setting")] 
        public ColorParameter fogColor = new ColorParameter(Color.white, true, false, false);
        public ClampedFloatParameter density = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

        [Header("Height Fog Setting")]
        public ClampedFloatParameter heightFogStart = new ClampedFloatParameter(20.0f, 0.0f, 1000.0f);
        public ClampedFloatParameter heightFogDensity = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);

        [Header("Distance Fog Setting")] // Linear
        public ClampedFloatParameter distanceFogMaxLength = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);
        public ClampedFloatParameter distanceFogDensity = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);

        [Header("Scattering Setting")]
        public ColorParameter dayScatteringColor = new ColorParameter(Color.white, true, false, false);
        public ColorParameter nightScatteringColor = new ColorParameter(Color.white, true, false, false);
        public ClampedFloatParameter scattering = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
        public ClampedFloatParameter scatteringRedWave = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);
        public ClampedFloatParameter scatteringGreenWave = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);
        public ClampedFloatParameter scatteringBlueWave = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);
        public ClampedFloatParameter scatteringMoon = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
        public ClampedFloatParameter scatteringFogDensity = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);

        [Header("Physic Setting")]
        public ClampedFloatParameter dayScatteringFac = new ClampedFloatParameter(1.0f, 0.0f, 1.0f);
        public ClampedFloatParameter nightScatteringFac = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
        public ClampedFloatParameter gDayMie = new ClampedFloatParameter(0.75f, 0.5f, 0.9999f);
        public ClampedFloatParameter gNightMie = new ClampedFloatParameter(0.75f, 0.5f, 0.9999f);

        public bool IsActive() => density.value <= float.Epsilon;

        public bool IsTileCompatible() => false;
    }
}