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

        public Vector3Parameter planePosition = new Vector3Parameter(Vector3.zero);
        public Vector3Parameter planeNormal = new Vector3Parameter(Vector3.up);

        public bool IsActive() => enable.value;

        public bool IsTileCompatible() => false;
    }
}