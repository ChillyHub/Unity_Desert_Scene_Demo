using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomRenderer
{
    public class ScreenSpacePlanarReflectionPass : ScriptableRenderPass
    {
        private ProfilingSampler _profilingSampler;
        
        private ComputeShader _cs;
        private RenderTextureDescriptor _descriptor;

        private bool _sync;
        
        private const string CsClearKernelName = "SSPRMappingCSClear";
        private const string CsMainKernelName = "SSPRMappingCSMain";
        private const string CsSyncKernelName = "SSPRMappingCSSync";

        private static readonly int UVMappingTextureId = Shader.PropertyToID("_UVMappingTexture");
        private static readonly int UVSyncMappingTextureId = Shader.PropertyToID("_UVSyncMappingTexture");
        private static readonly int CameraDepthTextureId = Shader.PropertyToID("_CameraDepthTexture");
        private static readonly int UVMappingWidth = Shader.PropertyToID("_UVMappingWidth");
        private static readonly int UVMappingHeight = Shader.PropertyToID("_UVMappingHeight");
        private static readonly int PlanePositionId = Shader.PropertyToID("_PlanePosition");
        private static readonly int PlaneNormalId = Shader.PropertyToID("_PlaneNormal");

        public ScreenSpacePlanarReflectionPass(string profilingTag)
        {
            this.profilingSampler = new ProfilingSampler(nameof(ScreenSpacePlanarReflectionPass));

            _profilingSampler = new ProfilingSampler(profilingTag);
        }
        
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var data = renderingData.cameraData.cameraTargetDescriptor;
            int width = data.width;
            int height = data.height;

            if (_sync)
            {
                _descriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.RInt, 0);
                _descriptor.colorFormat = RenderTextureFormat.RInt;
                _descriptor.enableRandomWrite = true;
                _descriptor.sRGB = false;

                cmd.GetTemporaryRT(UVSyncMappingTextureId, _descriptor);
                
                Shader.SetKeyword(GlobalKeyword.Create("_CS_SYNC_MAPPING"), true);
            }
            else
            {
                _descriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.RG32, 0);
                _descriptor.colorFormat = RenderTextureFormat.RG32;
                _descriptor.enableRandomWrite = true;
                _descriptor.sRGB = false;

                cmd.GetTemporaryRT(UVMappingTextureId, _descriptor);
                
                Shader.SetKeyword(GlobalKeyword.Create("_CS_SYNC_MAPPING"), false);
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var volume = VolumeManager.instance.stack.GetComponent<ScreenSpacePlanarReflection>();
            if (volume == null || !volume.IsActive())
            {
                return;
            }
            
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _profilingSampler))
            {
                // Ensure we flush our command-buffer before we render...
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                // Update
                int width = _descriptor.width;
                int height = _descriptor.height;
                cmd.SetComputeFloatParam(_cs, UVMappingWidth, width);
                cmd.SetComputeFloatParam(_cs, UVMappingHeight, height);
                cmd.SetComputeVectorParam(_cs, PlanePositionId, (Vector4)volume.planePosition.value);
                cmd.SetComputeVectorParam(_cs, PlaneNormalId, (Vector4)volume.planeNormal.value);
                
                if (_sync)
                {
                    // Clear
                    int kernel = _cs.FindKernel(CsClearKernelName);
                    cmd.SetComputeTextureParam(
                        _cs, kernel, UVSyncMappingTextureId, new RenderTargetIdentifier(UVSyncMappingTextureId));
                
                    uint x, y, z;
                    _cs.GetKernelThreadGroupSizes(kernel, out x, out y, out z);
                    int groupX = Mathf.CeilToInt((float)width / (float)x);
                    int groupY = Mathf.CeilToInt((float)height / (float)y);
                    cmd.DispatchCompute(_cs, kernel, groupX, groupY, 1);
                    
                    // Mapping
                    kernel = _cs.FindKernel(CsSyncKernelName);
                    cmd.SetComputeTextureParam(
                        _cs, kernel, UVSyncMappingTextureId, new RenderTargetIdentifier(UVSyncMappingTextureId));
                    cmd.SetComputeTextureParam(
                        _cs, kernel, CameraDepthTextureId, new RenderTargetIdentifier(CameraDepthTextureId));
                
                    _cs.GetKernelThreadGroupSizes(kernel, out x, out y, out z);
                    groupX = Mathf.CeilToInt((float)width / (float)x);
                    groupY = Mathf.CeilToInt((float)height / (float)y);
                    cmd.DispatchCompute(_cs, kernel, groupX, groupY, 1);
                }
                else
                {
                    // Clear
                    int kernel = _cs.FindKernel(CsClearKernelName);
                    cmd.SetComputeTextureParam(
                        _cs, kernel, UVMappingTextureId, new RenderTargetIdentifier(UVMappingTextureId));
                
                    uint x, y, z;
                    _cs.GetKernelThreadGroupSizes(kernel, out x, out y, out z);
                    int groupX = Mathf.CeilToInt((float)width / (float)x);
                    int groupY = Mathf.CeilToInt((float)height / (float)y);
                    cmd.DispatchCompute(_cs, kernel, groupX, groupY, 1);
                    
                    // Mapping
                    kernel = _cs.FindKernel(CsMainKernelName);
                    cmd.SetComputeTextureParam(
                        _cs, kernel, UVMappingTextureId, new RenderTargetIdentifier(UVMappingTextureId));
                    cmd.SetComputeTextureParam(
                        _cs, kernel, CameraDepthTextureId, new RenderTargetIdentifier(CameraDepthTextureId));
                
                    _cs.GetKernelThreadGroupSizes(kernel, out x, out y, out z);
                    groupX = Mathf.CeilToInt((float)width / (float)x);
                    groupY = Mathf.CeilToInt((float)height / (float)y);
                    cmd.DispatchCompute(_cs, kernel, groupX, groupY, 1);
                }
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            if (cmd == null)
                throw new System.ArgumentNullException("cmd");

            cmd.ReleaseTemporaryRT(_sync ? UVSyncMappingTextureId : UVMappingTextureId);
        }

        public void Setup(ComputeShader cs, bool sync)
        {
            this.renderPassEvent = RenderPassEvent.BeforeRenderingDeferredLights;
            _cs = cs;
            _sync = sync;
        }
    }
}