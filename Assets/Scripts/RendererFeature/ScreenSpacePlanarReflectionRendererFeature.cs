using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomRenderer
{
    public class ScreenSpacePlanarReflectionRendererFeature : ScriptableRendererFeature
    {
        public ComputeShader computeShader;
        public bool csThreadsSync = false;

        private ScreenSpacePlanarReflectionPass _pass;

        private const string ProfilingTag = "SSPR";
        
        public override void Create()
        {
            _pass = new ScreenSpacePlanarReflectionPass(ProfilingTag);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var volume = VolumeManager.instance.stack.GetComponent<ScreenSpacePlanarReflection>();
            if (volume == null || !volume.IsActive())
            {
                return;
            }

            _pass.Setup(computeShader, csThreadsSync);
            renderer.EnqueuePass(_pass);
        }
    }
}