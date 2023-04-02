using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomRenderer
{
    [Serializable]
    [VolumeComponentMenuForRenderPipeline("Post-processing/Screen Space Planar Reflection", 
        typeof(UniversalRenderPipeline))]
    public class ScreenSpacePlanarReflection : VolumeComponent, IPostProcessComponent
    {
        public BoolParameter enable = new BoolParameter(false, true);

        [NonSerialized]
        public Vector3 PlanePosition = Vector3.zero;
        [NonSerialized]
        public Vector3 PlaneNormal = Vector3.up;

        public bool IsActive() => enable.value;

        public bool IsTileCompatible() => false;
    }
}